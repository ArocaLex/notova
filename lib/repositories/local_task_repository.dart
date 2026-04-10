import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/app_database.dart';
import '../models/task_model.dart';

/// Repositorio local de tareas usando SQLite vía drift (ORM).
///
/// Funciones:
///   - Caché offline de las tareas del usuario.
///   - Sincronización unidireccional: Firestore → SQLite.
///   - Lectura desde SQLite cuando no hay conexión.
///
/// RAs cubiertos:
///   - RA2 (Acceso a Datos): Base de datos relacional (SQLite).
///   - RA3 (Acceso a Datos): ORM — drift mapea objetos Dart ↔ tablas SQL.
class LocalTaskRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LocalTaskRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  String? get _uid => _auth.currentUser?.uid;

  // ── Conversión TaskModel ↔ drift Companion ──────────────────────────

  /// Convierte un TaskModel (Firestore) a un Companion de drift (SQLite).
  LocalTasksCompanion _toCompanion(TaskModel task) {
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
    );
  }

  /// Convierte una fila de SQLite (LocalTask) a TaskModel de dominio.
  TaskModel _toTaskModel(LocalTask row) {
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
    );
  }

  // ── Lectura desde SQLite ────────────────────────────────────────────

  /// Tareas pendientes desde caché local.
  Future<List<TaskModel>> getPendingTasks() async {
    final rows = await _db.getPendingTasks();
    return rows.map(_toTaskModel).toList();
  }

  /// Tareas completadas desde caché local.
  Future<List<TaskModel>> getCompletedTasks() async {
    final rows = await _db.getCompletedTasks();
    return rows.map(_toTaskModel).toList();
  }

  /// Todas las tareas desde caché local.
  Future<List<TaskModel>> getAllTasks() async {
    final rows = await _db.getAllTasks();
    return rows.map(_toTaskModel).toList();
  }

  /// Stream reactivo de tareas pendientes.
  Stream<List<TaskModel>> watchPendingTasks() {
    return _db.watchPendingTasks().map(
      (rows) => rows.map(_toTaskModel).toList(),
    );
  }

  /// Stream reactivo de tareas completadas.
  Stream<List<TaskModel>> watchCompletedTasks() {
    return _db.watchCompletedTasks().map(
      (rows) => rows.map(_toTaskModel).toList(),
    );
  }

  // ── Sincronización Firestore → SQLite ───────────────────────────────

  /// Descarga todas las tareas de Firestore y las guarda en SQLite.
  Future<void> syncFromFirestore() async {
    if (_uid == null) return;

    final snap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .get();

    final companions = snap.docs.map((doc) {
      final task = TaskModel.fromFirestore(doc);
      return _toCompanion(task);
    }).toList();

    await _db.syncFromFirestore(companions);
    final total = await _db.getAllTasks();
    debugPrint('[SQLite Sync] ${total.length} tareas cacheadas en notova.db');
  }

  /// Limpia la caché local (al cerrar sesión).
  Future<void> clearLocalCache() async {
    await _db.clearAll();
  }
}
