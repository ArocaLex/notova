import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';

/// Repositorio de tareas del usuario autenticado.
///
/// Centraliza el acceso a la colección `/users/{uid}/tasks` en Firestore.
/// Proporciona operaciones CRUD, streams en tiempo real y la lógica de
/// completar tareas con recompensa de XP mediante [UserRepository].
class TasksRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// UID del usuario autenticado actualmente.
  String? get _uid => _auth.currentUser?.uid;

  /// Referencia a la colección de tareas del usuario autenticado.
  CollectionReference<Map<String, dynamic>>? get _tasksCol => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('tasks');

  /// Genera un ID válido de Firestore sin tocar la red. Útil para crear
  /// tareas en modo offline-first: el ID se asigna localmente y luego la
  /// sincronización en background hace `set` con ese mismo ID.
  String? generateTaskId() {
    if (_tasksCol == null) return null;
    return _tasksCol!.doc().id;
  }

  /// Escribe una tarea completa en Firestore usando un ID ya generado.
  ///
  /// Es idempotente: si la tarea ya existe, la sustituye mediante merge.
  Future<void> setTask({
    required String taskId,
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
    required bool isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    String? color,
  }) async {
    if (_tasksCol == null) return;
    await _tasksCol!.doc(taskId).set({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt) : null,
      'color': color,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt) : Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Retorna un stream de tareas pendientes ordenadas por fecha de creación
  /// descendente.
  Stream<List<TaskModel>> getPendingTasks() {
    if (_tasksCol == null) return const Stream.empty();

    return _tasksCol!
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  /// Retorna un stream de tareas completadas ordenadas por fecha de creación
  /// descendente.
  Stream<List<TaskModel>> getCompletedTasks() {
    if (_tasksCol == null) return const Stream.empty();

    return _tasksCol!
        .where('isCompleted', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  /// Actualiza los campos editables de una tarea existente en Firestore.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
    DateTime? dueDate,
    String? color,
  }) async {
    if (_tasksCol == null) return;

    await _tasksCol!.doc(taskId).update({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'color': color,
    });
  }

  /// Marca la tarea como completada, otorga [xpReward] al usuario y retorna
  /// `true` si se produjo un level-up.
  Future<bool> completeTask(String taskId, int xpReward) async {
    if (_tasksCol == null) return false;
    final uid = _uid;
    if (uid == null) return false;

    final taskRef = _tasksCol!.doc(taskId);
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction<bool>((tx) async {
      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) return false;
      final taskData = taskSnap.data() ?? const <String, dynamic>{};
      final alreadyGranted = taskData['xpGranted'] == true;
      if (alreadyGranted) return false;

      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) return false;
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final currentTotalXp = (userData['totalXpEver'] as num?)?.toInt() ?? 0;
      // Recalcula el nivel desde XP para corregir datos desincronizados en Firestore.
      final currentLevel = UserModel.levelFromXp(currentTotalXp);

      final nextTotalXp = currentTotalXp + xpReward;
      final nextLevel = UserModel.levelFromXp(nextTotalXp);
      final nextRank = UserModel.rankForLevel(nextLevel);

      tx.update(taskRef, {
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'xpGranted': true,
      });
      tx.update(userRef, {
        'totalXpEver': nextTotalXp,
        'level': nextLevel,
        'rank': nextRank,
      });

      return nextLevel > currentLevel;
    });
  }

  /// Elimina la tarea con [taskId] de Firestore.
  Future<void> deleteTask(String taskId) async {
    if (_tasksCol == null) return;
    await _tasksCol!.doc(taskId).delete();
  }

  /// Obtiene todas las tareas del usuario en una sola consulta Firestore,
  /// ordenadas por fecha de creación descendente.
  Future<List<TaskModel>> getAllTasks() async {
    if (_tasksCol == null) return [];

    final snap = await _tasksCol!.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList();
  }
}
