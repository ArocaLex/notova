import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';

/// Repositorio de tareas del usuario autenticado.
class TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// UID del usuario autenticado actualmente.
  String? get userId => _auth.currentUser?.uid;

  /// Referencia a la colección de tareas del usuario autenticado.
  CollectionReference<Map<String, dynamic>>? get tasksCollection => userId == null
      ? null
      : _db.collection('users').doc(userId).collection('tasks');

  /// Genera un ID válido de Firestore.
  String? generateId() {
    if (tasksCollection == null) return null;
    return tasksCollection!.doc().id;
  }

  /// Escribe una tarea completa en Firestore.
  Future<void> saveTask({
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
    if (tasksCollection == null) return;
    await tasksCollection!.doc(taskId).set({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt) : null,
      'color': color,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt) : Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Retorna un stream de tareas pendientes.
  Stream<List<TaskModel>> getPendingTasks() {
    if (tasksCollection == null) return const Stream.empty();

    return tasksCollection!
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  /// Retorna un stream de tareas completadas.
  Stream<List<TaskModel>> getCompletedTasks() {
    if (tasksCollection == null) return const Stream.empty();

    return tasksCollection!
        .where('isCompleted', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  /// Actualiza los campos editables de una tarea.
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
    DateTime? dueDate,
    String? color,
  }) async {
    if (tasksCollection == null) return;

    await tasksCollection!.doc(taskId).update({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'color': color,
    });
  }

  /// Marca la tarea como completada y otorga XP.
  ///
  /// Retorna `true` si el usuario subió de nivel.
  Future<bool> completeTask(String taskId, int xpReward) async {
    if (tasksCollection == null) return false;
    final uid = userId;
    if (uid == null) return false;

    final taskRef = tasksCollection!.doc(taskId);
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
      final currentLevel = UserModel.levelFromXp(currentTotalXp);

      final newTotalXp = currentTotalXp + xpReward;
      final newLevel = UserModel.levelFromXp(newTotalXp);
      final newRank = UserModel.rankForLevel(newLevel);

      tx.update(taskRef, {
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'xpGranted': true,
      });
      tx.update(userRef, {
        'totalXpEver': newTotalXp,
        'level': newLevel,
        'rank': newRank,
      });

      return newLevel > currentLevel;
    });
  }

  /// Elimina la tarea.
  Future<void> deleteTask(String taskId) async {
    if (tasksCollection == null) return;
    await tasksCollection!.doc(taskId).delete();
  }

  /// Obtiene todas las tareas.
  Future<List<TaskModel>> getAllTasks() async {
    if (tasksCollection == null) return [];

    final snap = await tasksCollection!.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList();
  }
}
