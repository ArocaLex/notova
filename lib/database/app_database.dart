import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Tabla SQLite para caché offline de tareas (RA2 + RA3 — Acceso a Datos).
///
/// Usa drift como ORM: las columnas se definen como propiedades Dart
/// y drift genera el SQL, las clases de datos y los DAOs automáticamente.
class LocalTasks extends Table {
  // Clave primaria: el ID del documento de Firestore
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get subtitle => text().withDefault(const Constant(''))();
  TextColumn get priority => text().withDefault(const Constant('MED'))();
  IntColumn get xpReward => integer().withDefault(const Constant(25))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Base de datos local de Notova con drift (ORM sobre SQLite).
@DriftDatabase(tables: [LocalTasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  /// Singleton — una sola instancia durante todo el ciclo de vida de la app.
  factory AppDatabase() {
    _instance ??= AppDatabase._internal(_openConnection());
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  // ── Queries: lectura ────────────────────────────────────────────────

  /// Todas las tareas pendientes, ordenadas por fecha de creación.
  Future<List<LocalTask>> getPendingTasks() {
    return (select(localTasks)
          ..where((t) => t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Todas las tareas completadas.
  Future<List<LocalTask>> getCompletedTasks() {
    return (select(localTasks)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  /// Todas las tareas (para exportación).
  Future<List<LocalTask>> getAllTasks() {
    return (select(localTasks)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Obtener una tarea por ID.
  Future<LocalTask?> getTaskById(String taskId) {
    return (select(localTasks)..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
  }

  /// Stream reactivo de tareas pendientes (para UI con StreamBuilder).
  Stream<List<LocalTask>> watchPendingTasks() {
    return (select(localTasks)
          ..where((t) => t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Stream reactivo de tareas completadas.
  Stream<List<LocalTask>> watchCompletedTasks() {
    return (select(localTasks)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  // ── Queries: escritura ──────────────────────────────────────────────

  /// Inserta o reemplaza una tarea (upsert).
  Future<void> upsertTask(LocalTasksCompanion task) {
    return into(localTasks).insertOnConflictUpdate(task);
  }

  /// Inserta múltiples tareas en batch (sincronización desde Firestore).
  Future<void> syncFromFirestore(List<LocalTasksCompanion> tasks) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localTasks, tasks);
    });
  }

  /// Marcar una tarea como completada.
  Future<void> markCompleted(String taskId) {
    return (update(localTasks)..where((t) => t.id.equals(taskId))).write(
      LocalTasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Eliminar una tarea.
  Future<void> deleteTask(String taskId) {
    return (delete(localTasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// Eliminar todas las tareas (para logout o reset).
  Future<void> clearAll() {
    return delete(localTasks).go();
  }
}

/// Abre la conexión a la base de datos SQLite en el directorio de documentos.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notova.db'));
    return NativeDatabase.createInBackground(file);
  });
}
