import 'dart:async';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/task_model.dart';
import '../repositories/audio_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

/// ViewModel de tareas — offline-first real.
///
/// SQLite es la fuente de verdad. Cada mutación:
///   1. Escribe en SQLite (síncrono, marcado pendingPush).
///   2. Actualiza la lista en memoria y notifica.
///   3. Empuja a Firestore en background (`unawaited`). Si falla, queda
///      `pendingPush=true` y se reintenta en el próximo arranque/refresh.
///
/// Los efectos secundarios (audio, notificaciones, racha) van cada uno en
/// su propio try/catch para que un fallo en ellos NUNCA cause rollback de
/// la mutación. Esto arregla el bug en el que completar una tarea sumaba
/// XP pero la dejaba en pendientes.
class TasksViewModel extends ChangeNotifier {
  late final TasksRepository _repository;
  late final UserRepository _userRepository;
  late final AudioRepository _audioRepository;
  late final NotificationRepository _notificationRepository;
  late final AppDatabase _db;

  StreamSubscription<User?>? _authSub;

  List<TaskModel> pending = [];
  List<TaskModel> completed = [];
  bool isLoading = true;
  String? errorMessage;

  TasksViewModel({
    TasksRepository? repository,
    UserRepository? userRepository,
    AudioRepository? audioRepository,
    NotificationRepository? notificationRepository,
    AppDatabase? db,
  })  : _repository = repository ?? TasksRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _audioRepository = audioRepository ?? AudioRepository(),
        _notificationRepository =
            notificationRepository ?? NotificationRepository(),
        _db = db ?? AppDatabase() {
    _loadFromLocalThenSync();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _loadFromLocalThenSync();
    });
  }

  // ── Carga: local primero, Firestore en background con MERGE ──────────────

  Future<void> _loadFromLocalThenSync() async {
    isLoading = true;
    notifyListeners();

    // 1. Lectura inmediata desde SQLite (fuente de verdad).
    try {
      final localPending = await _db.getPendingTasks();
      final localCompleted = await _db.getCompletedTasks();
      pending = localPending.map(_localToModel).toList();
      completed = localCompleted.map(_localToModel).toList();
    } catch (e) {
      debugPrint('[TasksVM] Error reading local DB: $e');
    }

    isLoading = false;
    notifyListeners();

    // 2. Sync en background: empujar pendientes + traer cambios remotos.
    unawaited(_backgroundSync());
  }

  /// Sincronización en segundo plano. Nunca lanza ni modifica `errorMessage`
  /// si la red no está disponible — el modo offline es funcional al 100%.
  Future<void> _backgroundSync() async {
    // 2a. Empujar mutaciones locales pendientes.
    try {
      final pendingPush = await _db.getPendingPushTasks();
      for (final row in pendingPush) {
        try {
          await _repository.setTask(
            taskId: row.id,
            title: row.title,
            subtitle: row.subtitle,
            priority: row.priority,
            xpReward: row.xpReward,
            isCompleted: row.isCompleted,
            dueDate: row.dueDate,
            createdAt: row.createdAt,
            completedAt: row.completedAt,
            color: row.color,
          );
          await _db.clearPendingPush(row.id);
        } catch (e) {
          debugPrint('[TasksVM] push pending failed for ${row.id}: $e');
          // Lo dejamos como pendingPush=true; reintentamos al siguiente sync.
        }
      }
    } catch (e) {
      debugPrint('[TasksVM] background push failed: $e');
    }

    // 2b. Bajar de Firestore y mergear sin pisar lo local.
    try {
      final remote = await _repository.getAllTasks();
      final companions = remote.map(_modelToCompanion).toList();
      await _db.mergeFromFirestore(companions);

      // Recargar UI desde SQLite tras merge.
      final localPending = await _db.getPendingTasks();
      final localCompleted = await _db.getCompletedTasks();
      pending = localPending.map(_localToModel).toList();
      completed = localCompleted.map(_localToModel).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TasksVM] Firestore pull failed (offline?): $e');
    }
  }

  Future<void> refresh() => _loadFromLocalThenSync();

  // ── Crear tarea (SQLite primero, Firestore en background) ────────────────

  Future<bool> createTask(
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
    String? color,
  }) async {
    errorMessage = null;

    // 1. Generar ID localmente (sin tocar la red).
    final taskId = _repository.generateTaskId();
    if (taskId == null) {
      errorMessage = 'Tienes que iniciar sesión para crear quests.';
      notifyListeners();
      return false;
    }

    final task = TaskModel(
      id: taskId,
      title: title,
      subtitle: subtitle,
      priority: priority,
      xpReward: xpReward,
      isCompleted: false,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      color: color,
    );

    // 2. Escribir en SQLite (fuente de verdad) marcado como pendingPush.
    try {
      await _db.upsertTask(_modelToCompanion(task, pendingPush: true));
    } catch (e) {
      errorMessage = 'No se pudo guardar la quest localmente.';
      notifyListeners();
      return false;
    }

    // 3. Actualizar UI inmediatamente.
    pending.insert(0, task);
    notifyListeners();

    // 4. Efectos secundarios (cada uno aislado — nunca rompen la creación).
    _safeNotify(
      title: '🎯 Nueva Quest añadida',
      body: '"$title" — ¡a por ella!',
      id: '${taskId}_created'.hashCode,
    );
    if (dueDate != null) {
      _safeScheduleReminder(taskId: taskId, title: title, dueDate: dueDate);
    }

    // 5. Push a Firestore en background.
    unawaited(_pushTask(task));

    return true;
  }

  // ── Editar tarea ─────────────────────────────────────────────────────────

  Future<bool> updateTask(
    String taskId,
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
    String? color,
  }) async {
    errorMessage = null;

    final idx = pending.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;
    final updated = pending[idx].copyWith(
      title: title,
      subtitle: subtitle,
      priority: priority,
      xpReward: xpReward,
      dueDate: dueDate,
      color: color,
    );

    try {
      await _db.upsertTask(_modelToCompanion(updated, pendingPush: true));
    } catch (e) {
      errorMessage = 'No se pudieron guardar los cambios.';
      notifyListeners();
      return false;
    }

    pending[idx] = updated;
    notifyListeners();

    _safeCancelReminder(taskId);
    if (dueDate != null) {
      _safeScheduleReminder(taskId: taskId, title: title, dueDate: dueDate);
    }

    unawaited(_pushTask(updated));
    return true;
  }

  // ── Completar tarea ──────────────────────────────────────────────────────

  /// Marca la tarea como completada. SQLite + UI son la fuente de verdad;
  /// Firestore y efectos secundarios viajan en segundo plano y nunca
  /// causan rollback (era el bug).
  Future<bool> toggleTaskCompletion(String taskId, int xpReward) async {
    final idx = pending.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;
    final task = pending[idx];
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    // 1. Escribir SQLite. Si falla, no movemos nada en la UI.
    try {
      await _db.markCompleted(taskId, needsPush: true);
    } catch (e) {
      errorMessage = 'No se pudo completar la quest localmente.';
      notifyListeners();
      return false;
    }

    // 2. UI optimista — local ya tiene la verdad.
    pending.removeAt(idx);
    completed.insert(0, completedTask);
    notifyListeners();

    // 3. Push a Firestore + XP en background. Si falla, queda pendingPush.
    bool didLevelUp = false;
    try {
      didLevelUp = await _repository.completeTask(taskId, xpReward);
      await _db.clearPendingPush(taskId);
    } catch (e) {
      debugPrint('[TasksVM] Firestore complete failed (offline?): $e');
      // Dejamos pendingPush=true; sync futura lo empujará.
      // El XP NO se sumó si Firestore falló — lo intentamos sumar local-only
      // sólo si tenemos conexión. Para offline, el XP llegará al sincronizar.
    }

    // 4. Efectos secundarios — aislados. Nunca causan rollback.
    _safeCancelReminder(taskId);
    _safeUpdateStreak();
    _safePlayTaskComplete();
    if (didLevelUp) _safePlayLevelUp();
    _safeNotify(
      title: '✅ Quest completada',
      body: '"${completedTask.title}" — +${completedTask.xpReward} XP',
      id: '${taskId}_done'.hashCode,
    );

    return didLevelUp;
  }

  // ── Utilidades ───────────────────────────────────────────────────────────

  Future<void> checkStreakOnView() async {
    await _userRepository.checkAndUpdateStreak();
  }

  Future<void> _pushTask(TaskModel task) async {
    try {
      await _repository.setTask(
        taskId: task.id,
        title: task.title,
        subtitle: task.subtitle,
        priority: task.priority,
        xpReward: task.xpReward,
        isCompleted: task.isCompleted,
        dueDate: task.dueDate,
        createdAt: task.createdAt,
        completedAt: task.completedAt,
        color: task.color,
      );
      await _db.clearPendingPush(task.id);
    } catch (e) {
      debugPrint('[TasksVM] _pushTask failed for ${task.id}: $e');
    }
  }

  // ── Wrappers seguros para efectos secundarios ────────────────────────────

  void _safeNotify({required String title, required String body, int? id}) {
    unawaited(() async {
      try {
        await _notificationRepository.showInstant(
            title: title, body: body, id: id);
      } catch (e) {
        debugPrint('[TasksVM] notify failed: $e');
      }
    }());
  }

  void _safeScheduleReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) {
    unawaited(() async {
      try {
        await _notificationRepository.scheduleTaskReminder(
            taskId: taskId, title: title, dueDate: dueDate);
      } catch (e) {
        debugPrint('[TasksVM] schedule reminder failed: $e');
      }
    }());
  }

  void _safeCancelReminder(String taskId) {
    unawaited(() async {
      try {
        await _notificationRepository.cancelTaskReminder(taskId);
      } catch (e) {
        debugPrint('[TasksVM] cancel reminder failed: $e');
      }
    }());
  }

  void _safeUpdateStreak() {
    unawaited(() async {
      try {
        await _userRepository.checkAndUpdateStreak();
      } catch (e) {
        debugPrint('[TasksVM] streak update failed: $e');
      }
    }());
  }

  void _safePlayTaskComplete() {
    unawaited(() async {
      try {
        await _audioRepository.playTaskComplete();
      } catch (e) {
        debugPrint('[TasksVM] audio task complete failed: $e');
      }
    }());
  }

  void _safePlayLevelUp() {
    unawaited(() async {
      try {
        await _audioRepository.playLevelUp();
      } catch (e) {
        debugPrint('[TasksVM] audio level up failed: $e');
      }
    }());
  }

  // ── Conversiones TaskModel ↔ SQLite ──────────────────────────────────────

  TaskModel _localToModel(LocalTask row) {
    return TaskModel(
      id: row.id,
      title: row.title,
      subtitle: row.subtitle,
      priority: row.priority,
      xpReward: row.xpReward,
      isCompleted: row.isCompleted,
      dueDate: row.dueDate,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
      color: row.color,
    );
  }

  LocalTasksCompanion _modelToCompanion(TaskModel task,
      {bool pendingPush = false}) {
    return LocalTasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      subtitle: Value(task.subtitle),
      priority: Value(task.priority),
      xpReward: Value(task.xpReward),
      isCompleted: Value(task.isCompleted),
      dueDate: Value(task.dueDate),
      createdAt: Value(task.createdAt),
      completedAt: Value(task.completedAt),
      color: Value(task.color),
      pendingPush: Value(pendingPush),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
