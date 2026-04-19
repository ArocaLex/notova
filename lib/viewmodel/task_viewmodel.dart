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

  /// Devuelve las tareas completadas el día de hoy
  List<TaskModel> get completedToday {
    final now = DateTime.now();
    return completed.where((t) =>
        t.completedAt != null &&
        t.completedAt!.year == now.year &&
        t.completedAt!.month == now.month &&
        t.completedAt!.day == now.day).toList();
  }

  /// Calcula el progreso diario (completadas hoy / (pendientes + completadas hoy))
  double get dailyProgress {
    final total = pending.length + completedToday.length;
    return total > 0 ? completedToday.length / total : 0.0;
  }

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

  /// Carga inmediatamente desde SQLite y luego sincroniza con Firestore en
  /// segundo plano mediante [_backgroundSync].
  Future<void> _loadFromLocalThenSync() async {
    isLoading = true;
    notifyListeners();

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

    unawaited(_backgroundSync());
  }

  /// Sincronización en segundo plano. Nunca lanza ni modifica `errorMessage`
  /// si la red no está disponible — el modo offline es funcional al 100%.
  Future<void> _backgroundSync() async {
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
        }
      }
    } catch (e) {
      debugPrint('[TasksVM] background push failed: $e');
    }

    try {
      final remote = await _repository.getAllTasks();
      final companions = remote.map(_modelToCompanion).toList();
      await _db.mergeFromFirestore(companions);

      final localPending = await _db.getPendingTasks();
      final localCompleted = await _db.getCompletedTasks();
      pending = localPending.map(_localToModel).toList();
      completed = localCompleted.map(_localToModel).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TasksVM] Firestore pull failed (offline?): $e');
    }
  }

  /// Recarga las tareas desde SQLite y dispara una sincronización en
  /// segundo plano.
  Future<void> refresh() => _loadFromLocalThenSync();

  /// Crea una nueva tarea y la persiste en SQLite como fuente de verdad.
  ///
  /// El ID se genera localmente para no depender de la red. La tarea se
  /// empuja a Firestore en background marcada con `pendingPush`. Retorna
  /// `true` si la operación local fue exitosa.
  Future<bool> createTask(
    String title,
    String subtitle,
    String priority,
    int xpReward, {
    DateTime? dueDate,
    String? color,
  }) async {
    errorMessage = null;

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

    try {
      await _db.upsertTask(_modelToCompanion(task, pendingPush: true));
    } catch (e) {
      errorMessage = 'No se pudo guardar la quest localmente.';
      notifyListeners();
      return false;
    }

    pending.insert(0, task);
    notifyListeners();

    _safeNotify(
      title: '🎯 Nueva Quest añadida',
      body: '"$title" — ¡a por ella!',
      id: '${taskId}_created'.hashCode,
    );
    if (dueDate != null) {
      _safeScheduleReminder(taskId: taskId, title: title, dueDate: dueDate);
    }

    unawaited(_pushTask(task));

    return true;
  }

  /// Actualiza los campos de una tarea existente, persiste el cambio en
  /// SQLite y empuja a Firestore en background.
  ///
  /// Retorna `true` si la actualización local fue exitosa.
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

    try {
      await _db.markCompleted(taskId, needsPush: true);
    } catch (e) {
      errorMessage = 'No se pudo completar la quest localmente.';
      notifyListeners();
      return false;
    }

    pending.removeAt(idx);
    completed.insert(0, completedTask);
    notifyListeners();

    bool didLevelUp = false;
    try {
      didLevelUp = await _repository.completeTask(taskId, xpReward);
      await _db.clearPendingPush(taskId);
    } catch (e) {
      debugPrint('[TasksVM] Firestore complete failed (offline?): $e');
    }

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

  /// Elimina permanentemente una tarea completada de SQLite y de Firestore.
  ///
  /// La eliminación local es inmediata; Firestore se actualiza en background.
  Future<void> deleteTask(String taskId) async {
    try {
      await _db.deleteTask(taskId);
    } catch (e) {
      debugPrint('[TasksVM] deleteTask local failed: $e');
      return;
    }
    completed.removeWhere((t) => t.id == taskId);
    notifyListeners();
    unawaited(() async {
      try {
        await _repository.deleteTask(taskId);
      } catch (e) {
        debugPrint('[TasksVM] deleteTask Firestore failed: $e');
      }
    }());
  }

  /// Elimina todas las tareas completadas de SQLite y de Firestore.
  Future<void> deleteAllCompleted() async {
    final ids = completed.map((t) => t.id).toList();
    for (final id in ids) {
      try {
        await _db.deleteTask(id);
      } catch (_) {}
    }
    completed.clear();
    notifyListeners();
    for (final id in ids) {
      unawaited(() async {
        try {
          await _repository.deleteTask(id);
        } catch (_) {}
      }());
    }
  }

  /// Verifica y actualiza la racha diaria del usuario.
  Future<void> checkStreakOnView() async {
    await _userRepository.checkAndUpdateStreak();
  }

  /// Empuja una [TaskModel] a Firestore y, si tiene éxito, limpia la marca
  /// `pendingPush` en SQLite.
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

  /// Muestra una notificación instantánea sin propagar el error si falla.
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

  /// Programa un recordatorio para la tarea sin propagar el error si falla.
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

  /// Cancela el recordatorio de la tarea sin propagar el error si falla.
  void _safeCancelReminder(String taskId) {
    unawaited(() async {
      try {
        await _notificationRepository.cancelTaskReminder(taskId);
      } catch (e) {
        debugPrint('[TasksVM] cancel reminder failed: $e');
      }
    }());
  }

  /// Actualiza la racha diaria sin propagar el error si falla.
  void _safeUpdateStreak() {
    unawaited(() async {
      try {
        await _userRepository.checkAndUpdateStreak();
      } catch (e) {
        debugPrint('[TasksVM] streak update failed: $e');
      }
    }());
  }

  /// Reproduce el sonido de tarea completada sin propagar el error si falla.
  void _safePlayTaskComplete() {
    unawaited(() async {
      try {
        await _audioRepository.playTaskComplete();
      } catch (e) {
        debugPrint('[TasksVM] audio task complete failed: $e');
      }
    }());
  }

  /// Reproduce el sonido de subida de nivel sin propagar el error si falla.
  void _safePlayLevelUp() {
    unawaited(() async {
      try {
        await _audioRepository.playLevelUp();
      } catch (e) {
        debugPrint('[TasksVM] audio level up failed: $e');
      }
    }());
  }

  /// Convierte una fila [LocalTask] de SQLite a un [TaskModel] de dominio.
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

  /// Convierte un [TaskModel] en un [LocalTasksCompanion] para drift.
  ///
  /// Si [pendingPush] es `true`, la fila queda marcada para ser enviada a
  /// Firestore en la siguiente sincronización.
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
