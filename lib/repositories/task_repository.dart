import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import 'user_repository.dart';

class TasksRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _tasksCol => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('tasks');

  // ── Crear tarea ────────────────────────────────────────────────────────

  Future<void> addTask({
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
    DateTime? dueDate,
  }) async {
    if (_tasksCol == null) return;

    await _tasksCol!.add({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'isCompleted': false,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Streams en tiempo real ─────────────────────────────────────────────

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

  // ── Editar tarea ─────────────────────────────────────────────────────

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
    DateTime? dueDate,
  }) async {
    if (_tasksCol == null) return;

    await _tasksCol!.doc(taskId).update({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
    });
  }

  // ── Completar tarea ────────────────────────────────────────────────────

  /// Marca la tarea como completada, otorga XP y retorna si hubo level-up.
  Future<bool> completeTask(String taskId, int xpReward) async {
    if (_tasksCol == null) return false;

    await _tasksCol!.doc(taskId).update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    final didLevelUp = await _userRepository.addXp(xpReward);
    return didLevelUp;
  }

  // ── Leer todas las tareas (para exportación) ───────────────────────────

  Future<List<TaskModel>> getAllTasks() async {
    if (_tasksCol == null) return [];

    final snap = await _tasksCol!.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList();
  }
}
