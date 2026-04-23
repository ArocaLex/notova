import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Tabla SQLite para caché offline de tareas.
///
/// Usa drift como ORM: las columnas se definen como propiedades Dart
/// y drift genera el SQL, las clases de datos y los DAOs automáticamente.
class LocalTasks extends Table {
  /// Clave primaria: identificador del documento Firestore o UUID asignado
  /// localmente cuando la tarea se crea sin conexión.
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get subtitle => text().withDefault(const Constant(''))();
  TextColumn get priority => text().withDefault(const Constant('MED'))();
  IntColumn get xpReward => integer().withDefault(const Constant(25))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get color => text().nullable()();

  /// Marca de mutación local pendiente de empujar a Firestore. Cuando vale
  /// `true` la fila tiene cambios locales que aún no se han sincronizado.
  /// La sync periódica busca estas filas y las empuja en background.
  BoolColumn get pendingPush => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cuenta de Google Calendar conectada (multi-cuenta).
///
/// Persistir esto permite restaurar la lista de cuentas tras un reinicio
/// sin que el usuario tenga que volver a vincular Google.
class LocalCalendarAccounts extends Table {
  TextColumn get email => text()();
  /// ARGB del color asignado a la cuenta para los puntitos del grid.
  IntColumn get colorValue => integer()();
  /// Índice usado en la paleta — para no repetir color al reconectar.
  IntColumn get colorIndex => integer().withDefault(const Constant(-1))();
  TextColumn get accessToken => text().withDefault(const Constant(''))();
  DateTimeColumn get tokenExpiry => dateTime().nullable()();
  DateTimeColumn get connectedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {email};
}

/// Calendario individual dentro de una cuenta de Google.
class LocalCalendars extends Table {
  TextColumn get id => text()();
  TextColumn get accountEmail => text()();
  TextColumn get summary => text().withDefault(const Constant('Calendario'))();
  TextColumn get backgroundColor => text().nullable()();
  TextColumn get accessRole => text().withDefault(const Constant('reader'))();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id, accountEmail};
}

/// Base de datos local de Notova con drift (ORM sobre SQLite).
@DriftDatabase(tables: [LocalTasks, LocalCalendarAccounts, LocalCalendars])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  /// Singleton — una sola instancia durante todo el ciclo de vida de la app.
  factory AppDatabase() {
    _instance ??= AppDatabase._internal(_openConnection());
    return _instance!;
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(localTasks, localTasks.color);
          }
          if (from < 3) {
            await migrator.createTable(localCalendarAccounts);
            await migrator.createTable(localCalendars);
          }
          if (from < 4) {
            await migrator.addColumn(localTasks, localTasks.pendingPush);
          }
        },
      );

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

  /// Tareas con cambios locales pendientes de subir a Firestore.
  Future<List<LocalTask>> getPendingPushTasks() {
    return (select(localTasks)..where((t) => t.pendingPush.equals(true))).get();
  }

  /// Inserta o reemplaza una tarea (upsert).
  Future<void> upsertTask(LocalTasksCompanion task) {
    return into(localTasks).insertOnConflictUpdate(task);
  }

  /// Sincronización desde Firestore: hace MERGE preservando filas locales
  /// con `pendingPush = true` (mutaciones aún no empujadas) y filas que
  /// existan localmente pero no en el snapshot remoto (creadas offline).
  Future<void> mergeFromFirestore(List<LocalTasksCompanion> remote) async {
    final remoteIds = remote.map((c) => c.id.value).toSet();
    final local = await select(localTasks).get();
    final pendingLocalIds = local
        .where((t) => t.pendingPush || !remoteIds.contains(t.id))
        .map((t) => t.id)
        .toSet();

    final toApply = remote
        .where((c) => !pendingLocalIds.contains(c.id.value))
        .toList();
    if (toApply.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localTasks, toApply);
    });
  }

  /// Marca una tarea como completada (con flag de sincronización).
  Future<void> markCompleted(String taskId, {bool needsPush = true}) {
    return (update(localTasks)..where((t) => t.id.equals(taskId))).write(
      LocalTasksCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
        pendingPush: Value(needsPush),
      ),
    );
  }

  /// Limpia el flag de pendingPush tras sincronizar exitosamente.
  Future<void> clearPendingPush(String taskId) {
    return (update(localTasks)..where((t) => t.id.equals(taskId))).write(
      const LocalTasksCompanion(pendingPush: Value(false)),
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

  /// Todas las cuentas de calendario guardadas.
  Future<List<LocalCalendarAccount>> getAllCalendarAccounts() {
    return (select(localCalendarAccounts)
          ..orderBy([(a) => OrderingTerm.asc(a.connectedAt)]))
        .get();
  }

  /// Calendarios de una cuenta concreta.
  Future<List<LocalCalendar>> getCalendarsForAccount(String email) {
    return (select(localCalendars)
          ..where((c) => c.accountEmail.equals(email)))
        .get();
  }

  /// Inserta o actualiza una cuenta.
  Future<void> upsertCalendarAccount(LocalCalendarAccountsCompanion acc) {
    return into(localCalendarAccounts).insertOnConflictUpdate(acc);
  }

  /// Reemplaza la lista de calendarios de una cuenta de forma atómica:
  /// borra los anteriores y escribe los nuevos. Conserva la visibilidad
  /// si el caller la pasa ya en `calendars`.
  Future<void> replaceCalendarsForAccount(
    String email,
    List<LocalCalendarsCompanion> calendars,
  ) async {
    await transaction(() async {
      await (delete(localCalendars)
            ..where((c) => c.accountEmail.equals(email)))
          .go();
      if (calendars.isNotEmpty) {
        await batch((b) {
          b.insertAllOnConflictUpdate(localCalendars, calendars);
        });
      }
    });
  }

  /// Actualiza la visibilidad de un calendario concreto.
  Future<void> setCalendarVisibility(
    String calendarId,
    String accountEmail,
    bool isVisible,
  ) {
    return (update(localCalendars)
          ..where((c) =>
              c.id.equals(calendarId) & c.accountEmail.equals(accountEmail)))
        .write(LocalCalendarsCompanion(isVisible: Value(isVisible)));
  }

  /// Borra una cuenta y sus calendarios.
  Future<void> deleteCalendarAccount(String email) async {
    await transaction(() async {
      await (delete(localCalendars)
            ..where((c) => c.accountEmail.equals(email)))
          .go();
      await (delete(localCalendarAccounts)
            ..where((a) => a.email.equals(email)))
          .go();
    });
  }

  /// Borra todas las cuentas y sus calendarios (logout).
  Future<void> clearAllCalendarAccounts() async {
    await transaction(() async {
      await delete(localCalendars).go();
      await delete(localCalendarAccounts).go();
    });
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
