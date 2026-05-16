import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Tabla SQLite para caché offline de tareas.
class TasksTable extends Table {
  TextColumn get idUsuario => text()();
  TextColumn get id => text()();
  TextColumn get titulo => text().withLength(min: 1)();
  TextColumn get subtitulo => text().withDefault(const Constant(''))();
  TextColumn get prioridad => text().withDefault(const Constant('MED'))();
  IntColumn get puntosXp => integer().withDefault(const Constant(100))();
  BoolColumn get estaTerminada => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fechaTope => dateTime().nullable()();
  DateTimeColumn get creadaEl => dateTime().nullable()();
  DateTimeColumn get terminadaEl => dateTime().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get pendienteSincro => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id, idUsuario};
}

/// Cuenta de Google Calendar conectada (multi-cuenta).
class AccountsTable extends Table {
  TextColumn get idUsuario => text()();
  TextColumn get email => text()();
  IntColumn get valorColor => integer()();
  IntColumn get indiceColor => integer().withDefault(const Constant(-1))();
  TextColumn get tokenAcceso => text().withDefault(const Constant(''))();
  DateTimeColumn get expiracionToken => dateTime().nullable()();
  DateTimeColumn get conectadaEl => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {email, idUsuario};
}

/// Calendario individual dentro de una cuenta de Google.
class CalendarsTable extends Table {
  TextColumn get idUsuario => text()();
  TextColumn get id => text()();
  TextColumn get emailCuenta => text()();
  TextColumn get resumen => text().withDefault(const Constant('Calendario'))();
  TextColumn get colorFondo => text().nullable()();
  TextColumn get rolAcceso => text().withDefault(const Constant('reader'))();
  BoolColumn get esVisible => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id, emailCuenta, idUsuario};
}

/// Base de datos local de Notova con drift (ORM sobre SQLite).
@DriftDatabase(tables: [TasksTable, AccountsTable, CalendarsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instancia;

  factory AppDatabase() {
    _instancia ??= AppDatabase._internal(_abrirConexion());
    return _instancia!;
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(tasksTable, tasksTable.color);
          }
          if (from < 3) {
            await migrator.createTable(accountsTable);
            await migrator.createTable(calendarsTable);
          }
          if (from < 4) {
            await migrator.addColumn(tasksTable, tasksTable.pendienteSincro);
          }
          if (from < 5) {
            // Purgar tablas antiguas para migrar a multi-usuario.
            await migrator.issueCustomQuery('DROP TABLE IF EXISTS local_tasks;');
            await migrator.issueCustomQuery('DROP TABLE IF EXISTS local_calendar_accounts;');
            await migrator.issueCustomQuery('DROP TABLE IF EXISTS local_calendars;');
            await migrator.createTable(tasksTable);
            await migrator.createTable(accountsTable);
            await migrator.createTable(calendarsTable);
          }
        },
      );

  // --- Tareas ---

  Future<List<TasksTableData>> obtenerPendientes(String uid) {
    return (select(tasksTable)
          ..where((t) => t.idUsuario.equals(uid) & t.estaTerminada.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.creadaEl)]))
        .get();
  }

  Future<List<TasksTableData>> obtenerHechas(String uid, {int limit = 100}) {
    return (select(tasksTable)
          ..where((t) => t.idUsuario.equals(uid) & t.estaTerminada.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.terminadaEl)])
          ..limit(limit))
        .get();
  }

  Future<List<TasksTableData>> obtenerTodas(String uid) {
    return (select(tasksTable)
          ..where((t) => t.idUsuario.equals(uid))
          ..orderBy([(t) => OrderingTerm.asc(t.creadaEl)]))
        .get();
  }

  Future<TasksTableData?> obtenerTareaPorId(String uid, String idTarea) {
    return (select(tasksTable)..where((t) => t.idUsuario.equals(uid) & t.id.equals(idTarea)))
        .getSingleOrNull();
  }

  Stream<List<TasksTableData>> escucharPendientes(String uid) {
    return (select(tasksTable)
          ..where((t) => t.idUsuario.equals(uid) & t.estaTerminada.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.creadaEl)]))
        .watch();
  }

  Stream<List<TasksTableData>> escucharHechas(String uid) {
    return (select(tasksTable)
          ..where((t) => t.idUsuario.equals(uid) & t.estaTerminada.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.terminadaEl)]))
        .watch();
  }

  Future<List<TasksTableData>> obtenerPendientesSincro(String uid) {
    return (select(tasksTable)..where((t) => t.idUsuario.equals(uid) & t.pendienteSincro.equals(true))).get();
  }

  Future<void> insertarTarea(TasksTableCompanion tarea) {
    return into(tasksTable).insertOnConflictUpdate(tarea);
  }

  Future<void> fusionarDesdeNube(String uid, List<TasksTableCompanion> remoto) async {
    final remoteIds = remoto.map((c) => c.id.value).toSet();
    final local = await (select(tasksTable)..where((t) => t.idUsuario.equals(uid))).get();
    final pendingLocalIds = local
        .where((t) => t.pendienteSincro || !remoteIds.contains(t.id))
        .map((t) => t.id)
        .toSet();

    final toApply = remoto
        .where((c) => !pendingLocalIds.contains(c.id.value))
        .toList();
    if (toApply.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(tasksTable, toApply);
    });
  }

  Future<void> marcarTerminada(String uid, String idTarea, {bool necesitaSubir = true}) {
    return (update(tasksTable)..where((t) => t.idUsuario.equals(uid) & t.id.equals(idTarea))).write(
      TasksTableCompanion(
        estaTerminada: const Value(true),
        terminadaEl: Value(DateTime.now()),
        pendienteSincro: Value(necesitaSubir),
      ),
    );
  }

  Future<void> limpiarPendienteSincro(String uid, String idTarea) {
    return (update(tasksTable)..where((t) => t.idUsuario.equals(uid) & t.id.equals(idTarea))).write(
      const TasksTableCompanion(pendienteSincro: Value(false)),
    );
  }

  Future<void> borrarTarea(String uid, String idTarea) {
    return (delete(tasksTable)..where((t) => t.idUsuario.equals(uid) & t.id.equals(idTarea))).go();
  }

  Future<void> borrarTodasLasTareas(String uid) {
    return (delete(tasksTable)..where((t) => t.idUsuario.equals(uid))).go();
  }

  // --- Calendarios ---

  Future<List<AccountsTableData>> obtenerTodasLasCuentas(String uid) {
    return (select(accountsTable)
          ..where((a) => a.idUsuario.equals(uid))
          ..orderBy([(a) => OrderingTerm.asc(a.conectadaEl)]))
        .get();
  }

  Future<List<CalendarsTableData>> obtenerCalendariosDeCuenta(String uid, String email) {
    return (select(calendarsTable)
          ..where((c) => c.idUsuario.equals(uid) & c.emailCuenta.equals(email)))
        .get();
  }

  Future<void> insertarCuenta(AccountsTableCompanion cuenta) {
    return into(accountsTable).insertOnConflictUpdate(cuenta);
  }

  Future<void> reemplazarCalendariosDeCuenta(
    String uid,
    String email,
    List<CalendarsTableCompanion> calendarios,
  ) async {
    await transaction(() async {
      await (delete(calendarsTable)
            ..where((c) => c.idUsuario.equals(uid) & c.emailCuenta.equals(email)))
          .go();
      if (calendarios.isNotEmpty) {
        await batch((b) {
          b.insertAllOnConflictUpdate(calendarsTable, calendarios);
        });
      }
    });
  }

  Future<void> cambiarVisibilidadCalendario(
    String uid,
    String idCalendario,
    String emailCuenta,
    bool esVisible,
  ) {
    return (update(calendarsTable)
          ..where((c) =>
              c.idUsuario.equals(uid) & c.id.equals(idCalendario) & c.emailCuenta.equals(emailCuenta)))
        .write(CalendarsTableCompanion(esVisible: Value(esVisible)));
  }

  Future<void> borrarCuenta(String uid, String email) async {
    await transaction(() async {
      await (delete(calendarsTable)
            ..where((c) => c.idUsuario.equals(uid) & c.emailCuenta.equals(email)))
          .go();
      await (delete(accountsTable)
            ..where((a) => a.idUsuario.equals(uid) & a.email.equals(email)))
          .go();
    });
  }

  Future<void> borrarTodasLasCuentas(String uid) async {
    await transaction(() async {
      await (delete(calendarsTable)..where((c) => c.idUsuario.equals(uid))).go();
      await (delete(accountsTable)..where((a) => a.idUsuario.equals(uid))).go();
    });
  }
}

Future<String> _obtenerClaveBD() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  const keyAlias = 'notova_db_key';
  var key = await storage.read(key: keyAlias);
  if (key == null) {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await storage.write(key: keyAlias, value: key);
  }
  return key;
}

LazyDatabase _abrirConexion() {
  return LazyDatabase(() async {
    final dbKey = await _obtenerClaveBD();
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notova.db'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute("PRAGMA key = '$dbKey';"),
    );
  });
}
