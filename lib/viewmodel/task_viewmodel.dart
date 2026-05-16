import 'dart:async';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/task_model.dart';
import '../repositories/audio_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';
import '../services/daily_counter_service.dart';

/// ViewModel de tareas (quests).
///
/// Mantiene listas locales de tareas pendientes y completadas, y orquesta
/// el flujo offline-first: SQLite es source of truth de la UI; Firestore se
/// sincroniza en background.
class TasksViewModel extends ChangeNotifier {
  late final TaskRepository _repository;
  late final UserRepository _userRepository;
  late final AudioRepository _audioRepository;
  late final NotificationRepository _notificationRepository;
  late final AppDatabase _db;

  StreamSubscription<firebase_auth.User?>? _authSub;
  Timer? _midnightTimer;

  List<TaskModel> pending = [];
  List<TaskModel> completed = [];
  bool isLoading = true;
  String? errorMessage;

  int _completedTodayCount = 0;
  late final DailyCounterService _dailyCounter;

  String? get _userId =>
      firebase_auth.FirebaseAuth.instance.currentUser?.uid;

  /// Tareas pendientes con fecha de vencimiento en los próximos 7 días,
  /// ordenadas de más cercana a más lejana.
  List<TaskModel> get pendingNext7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = DateTime(now.year, now.month, now.day + 7, 23, 59, 59);
    return pending
        .where((t) =>
            t.dueDate != null &&
            !t.dueDate!.isBefore(today) &&
            !t.dueDate!.isAfter(limit))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  /// Tareas completadas hoy — filtro puro sin efectos secundarios.
  List<TaskModel> get completedToday {
    final now = DateTime.now();
    return completed
        .where(
          (t) =>
              t.completedAt != null &&
              t.completedAt!.year == now.year &&
              t.completedAt!.month == now.month &&
              t.completedAt!.day == now.day,
        )
        .toList();
  }

  double get dailyProgress {
    final total = _completedTodayCount + pending.length;
    return total > 0 ? _completedTodayCount / total : 0.0;
  }

  int get completedTodayProgressCount => _completedTodayCount;
  int get totalDailyProgressCount => _completedTodayCount + pending.length;

  TasksViewModel({
    TaskRepository? repository,
    UserRepository? userRepository,
    AudioRepository? audioRepository,
    NotificationRepository? notificationRepository,
    AppDatabase? db,
    DailyCounterService? dailyCounter,
  })  : _repository = repository ?? TaskRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _audioRepository = audioRepository ?? AudioRepository(),
        _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        _db = db ?? AppDatabase(),
        _dailyCounter = dailyCounter ?? DailyCounterService() {
    _authSub =
        firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        pending.clear();
        completed.clear();
        _completedTodayCount = 0;
        isLoading = false;
        _midnightTimer?.cancel();
        _midnightTimer = null;
        notifyListeners();
      } else {
        _loadFromLocalThenSync();
      }
    });
  }

  /// Programa un timer que se dispara justo después de las 00:00 para resetear
  /// el contador diario y reprogramarse para el día siguiente.
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final delay = tomorrow.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(delay, () {
      final uid = _userId;
      if (uid != null) {
        unawaited(_dailyCounter.resetForUser(uid));
      }
      _completedTodayCount = 0;
      notifyListeners();
      _scheduleMidnightReset();
    });
  }

  /// Carga inmediatamente desde SQLite y luego sincroniza con Firestore en
  /// segundo plano mediante [_backgroundSync].
  Future<void> _loadFromLocalThenSync() async {
    final uid = _userId;
    if (uid == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final dbResults = await Future.wait<List<TasksTableData>>([
        _db.obtenerPendientes(uid),
        _db.obtenerHechas(uid),
      ]);
      final p = dbResults[0].map(_rowToModel).toList();
      _sortTasks(p);
      pending = p;
      completed = dbResults[1].map(_rowToModel).toList();
      _completedTodayCount = await _dailyCounter.getCount(uid);
    } catch (e) {
      debugPrint('[TasksVM] Error reading local DB: $e');
    }

    isLoading = false;
    notifyListeners();

    _scheduleMidnightReset();
    unawaited(_backgroundSync());
  }

  /// Sincronización en segundo plano. Nunca lanza ni modifica `errorMessage`
  /// si la red no está disponible — el modo offline es funcional al 100%.
  Future<void> _backgroundSync() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final pendingPush = await _db.obtenerPendientesSincro(uid);
      for (final row in pendingPush) {
        try {
          if (row.estaTerminada) {
            await _repository.completeTask(row.id, row.puntosXp);
          } else {
            await _repository.saveTask(
              taskId: row.id,
              title: row.titulo,
              subtitle: row.subtitulo,
              priority: row.prioridad,
              xpReward: row.puntosXp,
              isCompleted: row.estaTerminada,
              dueDate: row.fechaTope,
              createdAt: row.creadaEl,
              completedAt: row.terminadaEl,
              color: row.color,
            );
          }
          await _db.limpiarPendienteSincro(uid, row.id);
        } catch (e) {
          debugPrint('[TasksVM] Error pushing ${row.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[TasksVM] Error en sincro background: $e');
    }

    try {
      final remote = await _repository.getAllTasks();
      final companions = remote.map((m) => _modelToCompanion(uid, m)).toList();
      await _db.fusionarDesdeNube(uid, companions);

      final dbResults = await Future.wait<List<TasksTableData>>([
        _db.obtenerPendientes(uid),
        _db.obtenerHechas(uid),
      ]);
      final p = dbResults[0].map(_rowToModel).toList();
      _sortTasks(p);
      pending = p;
      completed = dbResults[1].map(_rowToModel).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TasksVM] Error pulling from Firestore: $e');
    }
  }

  Future<void> refresh() => _loadFromLocalThenSync();

  void checkStreakOnView() => _updateStreak();

  /// Crea una nueva tarea local + Firestore.
  Future<bool> createTask(
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
    String? color,
  }) async {
    final uid = _userId;
    if (uid == null) return false;

    final newId = _repository.generateId();
    if (newId == null) return false;

    final t = TaskModel(
      id: newId,
      title: title,
      subtitle: subtitle,
      priority: priority,
      xpReward: xpReward,
      isCompleted: false,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      color: color,
    );

    try {
      await _db.insertarTarea(_modelToCompanion(uid, t, pending: true));
    } catch (_) {
      return false;
    }

    final p = [t, ...pending];
    _sortTasks(p);
    pending = p;
    notifyListeners();

    _showLocalNotification(
      title: '🎯 Tarea añadida',
      body: '"$title" — ¡a por ella!',
      id: '${newId}_created'.hashCode,
    );
    if (dueDate != null) {
      _scheduleReminder(taskId: newId, title: title, dueDate: dueDate);
    }

    unawaited(_pushToCloud(uid, t));

    return true;
  }

  Future<bool> updateTask(
    String taskId,
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
    String? color,
  }) async {
    final uid = _userId;
    if (uid == null) return false;

    final index = pending.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;
    final edited = pending[index].copyWith(
      title: title,
      subtitle: subtitle,
      priority: priority,
      xpReward: xpReward,
      dueDate: dueDate,
      color: color,
    );

    try {
      await _db.insertarTarea(_modelToCompanion(uid, edited, pending: true));
    } catch (_) {
      return false;
    }

    final p = List<TaskModel>.from(pending);
    p[index] = edited;
    _sortTasks(p);
    pending = p;
    notifyListeners();

    _cancelReminder(taskId);
    if (dueDate != null) {
      _scheduleReminder(taskId: taskId, title: title, dueDate: dueDate);
    }

    unawaited(_pushToCloud(uid, edited));
    return true;
  }

  /// Marca la tarea como completada. Devuelve `true` si subió de nivel.
  Future<bool> toggleTaskCompletion(String taskId, int xpReward) async {
    final uid = _userId;
    if (uid == null) return false;

    final index = pending.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;
    final t = pending[index];
    final completedTask =
        t.copyWith(isCompleted: true, completedAt: DateTime.now());

    try {
      await _db.marcarTerminada(uid, taskId, necesitaSubir: true);
    } catch (_) {
      return false;
    }

    final newPending = List<TaskModel>.from(pending)..removeAt(index);
    pending = newPending;
    completed = [completedTask, ...completed];
    _completedTodayCount++;
    unawaited(_dailyCounter.increment(uid));
    notifyListeners();

    bool didLevelUp = false;
    try {
      didLevelUp = await _repository.completeTask(taskId, xpReward);
      await _db.limpiarPendienteSincro(uid, taskId);
    } catch (e) {
      debugPrint('[TasksVM] Error en Firestore: $e');
    }

    _cancelReminder(taskId);
    _updateStreak();
    _refreshBadges();
    _playCompletedSound();
    if (didLevelUp) _playLevelUpSound();
    _showLocalNotification(
      title: '✅ Tarea completada',
      body: '"${completedTask.title}" — +${completedTask.xpReward} XP',
      id: '${taskId}_done'.hashCode,
    );

    return didLevelUp;
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _userId;
    if (uid == null) return;

    completed = List.from(completed)..removeWhere((t) => t.id == taskId);
    pending = List.from(pending)..removeWhere((t) => t.id == taskId);
    notifyListeners();

    unawaited(() async {
      try {
        await _db.borrarTarea(uid, taskId);
      } catch (e) {
        debugPrint('[TasksVM] Error borrar local: $e');
      }
      try {
        await _repository.deleteTask(taskId);
      } catch (e) {
        debugPrint('[TasksVM] Error borrar Firestore: $e');
      }
    }());
  }

  Future<void> deleteAllCompleted() async {
    final uid = _userId;
    if (uid == null) return;

    final ids = completed.map((t) => t.id).toList();
    completed = [];
    notifyListeners();

    unawaited(() async {
      for (final id in ids) {
        try {
          await _db.borrarTarea(uid, id);
        } catch (_) {}
        try {
          await _repository.deleteTask(id);
        } catch (_) {}
      }
    }());
  }

  Future<void> _pushToCloud(String uid, TaskModel t) async {
    try {
      if (t.isCompleted) {
        await _repository.completeTask(t.id, t.xpReward);
      } else {
        await _repository.saveTask(
          taskId: t.id,
          title: t.title,
          subtitle: t.subtitle,
          priority: t.priority,
          xpReward: t.xpReward,
          isCompleted: t.isCompleted,
          dueDate: t.dueDate,
          createdAt: t.createdAt,
          completedAt: t.completedAt,
          color: t.color,
        );
      }
      await _db.limpiarPendienteSincro(uid, t.id);
    } catch (e) {
      debugPrint('[TasksVM] Fallo al subir tarea ${t.id}: $e');
    }
  }

  void _showLocalNotification({
    required String title,
    required String body,
    int? id,
  }) {
    unawaited(() async {
      try {
        await _notificationRepository.showImmediate(
          title: title,
          body: body,
          id: id,
        );
      } catch (e) {
        debugPrint('[TasksVM] Fallo al notificar: $e');
      }
    }());
  }

  void _scheduleReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) {
    unawaited(() async {
      try {
        await _notificationRepository.scheduleTaskReminder(
          taskId: taskId,
          title: title,
          dueDate: dueDate,
        );
      } catch (e) {
        debugPrint('[TasksVM] Fallo al programar aviso: $e');
      }
    }());
  }

  void _cancelReminder(String taskId) {
    unawaited(() async {
      try {
        await _notificationRepository.cancelTaskReminder(taskId);
      } catch (e) {
        debugPrint('[TasksVM] Fallo al cancelar aviso: $e');
      }
    }());
  }

  void _refreshBadges() {
    unawaited(() async {
      try {
        await _userRepository.refreshBadges();
      } catch (e) {
        debugPrint('[TasksVM] Fallo al refrescar badges: $e');
      }
    }());
  }

  void _updateStreak() {
    unawaited(() async {
      try {
        await _userRepository.checkAndUpdateStreak();
      } catch (e) {
        debugPrint('[TasksVM] Fallo al actualizar racha: $e');
      }
    }());
  }

  void _playCompletedSound() {
    unawaited(() async {
      try {
        await _audioRepository.playTaskCompleted();
      } catch (e) {
        debugPrint('[TasksVM] Fallo al sonar: $e');
      }
    }());
  }

  void _playLevelUpSound() {
    unawaited(() async {
      try {
        await _audioRepository.playLevelUp();
      } catch (e) {
        debugPrint('[TasksVM] Fallo al sonar subida: $e');
      }
    }());
  }

  void _sortTasks(List<TaskModel> list) {
    list.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      
      final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
  }

  TaskModel _rowToModel(TasksTableData row) {
    return TaskModel(
      id: row.id,
      title: row.titulo,
      subtitle: row.subtitulo,
      priority: row.prioridad,
      xpReward: row.puntosXp,
      isCompleted: row.estaTerminada,
      dueDate: row.fechaTope,
      createdAt: row.creadaEl,
      completedAt: row.terminadaEl,
      color: row.color,
    );
  }

  TasksTableCompanion _modelToCompanion(
    String uid,
    TaskModel t, {
    bool pending = false,
  }) {
    return TasksTableCompanion(
      idUsuario: Value(uid),
      id: Value(t.id),
      titulo: Value(t.title),
      subtitulo: Value(t.subtitle),
      prioridad: Value(t.priority),
      puntosXp: Value(t.xpReward),
      estaTerminada: Value(t.isCompleted),
      fechaTope: Value(t.dueDate),
      creadaEl: Value(t.createdAt),
      terminadaEl: Value(t.completedAt),
      color: Value(t.color),
      pendienteSincro: Value(pending),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }
}
