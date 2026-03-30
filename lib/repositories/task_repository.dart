import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_repository.dart';

class TasksRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();

  // Obtenemos el ID del usuario que tiene la sesión iniciada
  String? get _uid => _auth.currentUser?.uid;

  /// 1. CREAR UNA NUEVA TAREA EN FIRESTORE
  Future<void> addTask({
    required String title,
    required String subtitle,
    required String priority,
    required int xpReward,
  }) async {
    if (_uid == null) return;

    // Crea un documento nuevo dentro de la carpeta 'tasks' de este usuario
    await _db.collection('users').doc(_uid).collection('tasks').add({
      'title': title,
      'subtitle': subtitle,
      'priority': priority,
      'xpReward': xpReward,
      'isCompleted': false, // Por defecto nace sin completar
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 2. LEER LAS TAREAS PENDIENTES EN TIEMPO REAL
  Stream<QuerySnapshot> getPendingTasks() {
    if (_uid == null) return const Stream.empty();

    // Filtra las tareas buscando solo las que tienen 'isCompleted' en false
    return _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 3. COMPLETAR TAREA Y DAR EXPERIENCIA AL MISMO TIEMPO
  Future<void> completeTask(String taskId, int xpReward) async {
    if (_uid == null) return;

    // Marcamos la tarea como completada
    final taskRef = _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId);

    await taskRef.update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Sumamos XP con logica de level-up via UserRepository
    await _userRepository.addXp(xpReward);
  }

  /// 4. LEER LAS TAREAS COMPLETADAS EN TIEMPO REAL
  Stream<QuerySnapshot> getCompletedTasks() {
    if (_uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .where('isCompleted', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
