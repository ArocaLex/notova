import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/app_database.dart';
import '../models/task_model.dart';

/// Repositorio local de tareas usando SQLite.
///
/// Encapsula el `AppDatabase` (cuyas tablas conservan nombres en español por
/// motivos de compatibilidad de schema) y expone una API en inglés con
/// modelos [TaskModel].
class LocalTaskRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LocalTaskRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  String? get userId => _auth.currentUser?.uid;

  /// Convierte un [TaskModel] al companion de drift.
  TasksTableCompanion _toCompanion(TaskModel task) {
    return TasksTableCompanion(
      idUsuario: Value(userId!),
      id: Value(task.id),
      titulo: Value(task.title),
      subtitulo: Value(task.subtitle),
      prioridad: Value(task.priority),
      puntosXp: Value(task.xpReward),
      estaTerminada: Value(task.isCompleted),
      fechaTope: Value(task.dueDate),
      creadaEl: Value(task.createdAt),
      terminadaEl: Value(task.completedAt),
    );
  }

  /// Convierte una fila de SQLite a [TaskModel].
  TaskModel _fromRow(TasksTableData row) {
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
    );
  }

  /// Retorna las tareas pendientes almacenadas en la caché local.
  Future<List<TaskModel>> getPendingTasks() async {
    if (userId == null) return [];
    final rows = await _db.obtenerPendientes(userId!);
    return rows.map(_fromRow).toList();
  }

  /// Retorna las tareas completadas almacenadas en la caché local.
  Future<List<TaskModel>> getCompletedTasks() async {
    if (userId == null) return [];
    final rows = await _db.obtenerHechas(userId!);
    return rows.map(_fromRow).toList();
  }

  /// Retorna todas las tareas almacenadas en la caché local.
  Future<List<TaskModel>> getAllTasks() async {
    if (userId == null) return [];
    final rows = await _db.obtenerTodas(userId!);
    return rows.map(_fromRow).toList();
  }

  /// Stream reactivo de tareas pendientes.
  Stream<List<TaskModel>> watchPending() {
    if (userId == null) return Stream.value([]);
    return _db.escucharPendientes(userId!).map(
      (rows) => rows.map(_fromRow).toList(),
    );
  }

  /// Stream reactivo de tareas completadas.
  Stream<List<TaskModel>> watchCompleted() {
    if (userId == null) return Stream.value([]);
    return _db.escucharHechas(userId!).map(
      (rows) => rows.map(_fromRow).toList(),
    );
  }

  /// Descarga todas las tareas de Firestore y las fusiona con SQLite.
  Future<void> syncFromFirestore() async {
    if (userId == null) return;

    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    final companions = snap.docs.map((doc) {
      final t = TaskModel.fromFirestore(doc);
      return _toCompanion(t);
    }).toList();

    await _db.fusionarDesdeNube(userId!, companions);
    final all = await _db.obtenerTodas(userId!);
    debugPrint('[Sync Local] ${all.length} tareas en BD para $userId');
  }

  /// Limpia la caché local del usuario dado (al cerrar sesión o eliminar cuenta).
  ///
  /// Recibe [uid] explícito para evitar depender de [FirebaseAuth.currentUser],
  /// que puede ser null si Firebase ya ha procesado el signOut.
  Future<void> clearLocalCache(String uid) async {
    await _db.borrarTodasLasTareas(uid);
    await _db.borrarTodasLasCuentas(uid);
  }
}
