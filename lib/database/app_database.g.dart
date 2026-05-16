// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTableTable extends TasksTable
    with TableInfo<$TasksTableTable, TasksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idUsuarioMeta = const VerificationMeta(
    'idUsuario',
  );
  @override
  late final GeneratedColumn<String> idUsuario = GeneratedColumn<String>(
    'id_usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtituloMeta = const VerificationMeta(
    'subtitulo',
  );
  @override
  late final GeneratedColumn<String> subtitulo = GeneratedColumn<String>(
    'subtitulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _prioridadMeta = const VerificationMeta(
    'prioridad',
  );
  @override
  late final GeneratedColumn<String> prioridad = GeneratedColumn<String>(
    'prioridad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MED'),
  );
  static const VerificationMeta _puntosXpMeta = const VerificationMeta(
    'puntosXp',
  );
  @override
  late final GeneratedColumn<int> puntosXp = GeneratedColumn<int>(
    'puntos_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _estaTerminadaMeta = const VerificationMeta(
    'estaTerminada',
  );
  @override
  late final GeneratedColumn<bool> estaTerminada = GeneratedColumn<bool>(
    'esta_terminada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("esta_terminada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fechaTopeMeta = const VerificationMeta(
    'fechaTope',
  );
  @override
  late final GeneratedColumn<DateTime> fechaTope = GeneratedColumn<DateTime>(
    'fecha_tope',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadaElMeta = const VerificationMeta(
    'creadaEl',
  );
  @override
  late final GeneratedColumn<DateTime> creadaEl = GeneratedColumn<DateTime>(
    'creada_el',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _terminadaElMeta = const VerificationMeta(
    'terminadaEl',
  );
  @override
  late final GeneratedColumn<DateTime> terminadaEl = GeneratedColumn<DateTime>(
    'terminada_el',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendienteSincroMeta = const VerificationMeta(
    'pendienteSincro',
  );
  @override
  late final GeneratedColumn<bool> pendienteSincro = GeneratedColumn<bool>(
    'pendiente_sincro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente_sincro" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    idUsuario,
    id,
    titulo,
    subtitulo,
    prioridad,
    puntosXp,
    estaTerminada,
    fechaTope,
    creadaEl,
    terminadaEl,
    color,
    pendienteSincro,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_usuario')) {
      context.handle(
        _idUsuarioMeta,
        idUsuario.isAcceptableOrUnknown(data['id_usuario']!, _idUsuarioMeta),
      );
    } else if (isInserting) {
      context.missing(_idUsuarioMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('subtitulo')) {
      context.handle(
        _subtituloMeta,
        subtitulo.isAcceptableOrUnknown(data['subtitulo']!, _subtituloMeta),
      );
    }
    if (data.containsKey('prioridad')) {
      context.handle(
        _prioridadMeta,
        prioridad.isAcceptableOrUnknown(data['prioridad']!, _prioridadMeta),
      );
    }
    if (data.containsKey('puntos_xp')) {
      context.handle(
        _puntosXpMeta,
        puntosXp.isAcceptableOrUnknown(data['puntos_xp']!, _puntosXpMeta),
      );
    }
    if (data.containsKey('esta_terminada')) {
      context.handle(
        _estaTerminadaMeta,
        estaTerminada.isAcceptableOrUnknown(
          data['esta_terminada']!,
          _estaTerminadaMeta,
        ),
      );
    }
    if (data.containsKey('fecha_tope')) {
      context.handle(
        _fechaTopeMeta,
        fechaTope.isAcceptableOrUnknown(data['fecha_tope']!, _fechaTopeMeta),
      );
    }
    if (data.containsKey('creada_el')) {
      context.handle(
        _creadaElMeta,
        creadaEl.isAcceptableOrUnknown(data['creada_el']!, _creadaElMeta),
      );
    }
    if (data.containsKey('terminada_el')) {
      context.handle(
        _terminadaElMeta,
        terminadaEl.isAcceptableOrUnknown(
          data['terminada_el']!,
          _terminadaElMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('pendiente_sincro')) {
      context.handle(
        _pendienteSincroMeta,
        pendienteSincro.isAcceptableOrUnknown(
          data['pendiente_sincro']!,
          _pendienteSincroMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, idUsuario};
  @override
  TasksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasksTableData(
      idUsuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_usuario'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      titulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}titulo'],
      )!,
      subtitulo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitulo'],
      )!,
      prioridad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prioridad'],
      )!,
      puntosXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}puntos_xp'],
      )!,
      estaTerminada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}esta_terminada'],
      )!,
      fechaTope: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_tope'],
      ),
      creadaEl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creada_el'],
      ),
      terminadaEl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}terminada_el'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      pendienteSincro: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente_sincro'],
      )!,
    );
  }

  @override
  $TasksTableTable createAlias(String alias) {
    return $TasksTableTable(attachedDatabase, alias);
  }
}

class TasksTableData extends DataClass implements Insertable<TasksTableData> {
  final String idUsuario;
  final String id;
  final String titulo;
  final String subtitulo;
  final String prioridad;
  final int puntosXp;
  final bool estaTerminada;
  final DateTime? fechaTope;
  final DateTime? creadaEl;
  final DateTime? terminadaEl;
  final String? color;
  final bool pendienteSincro;
  const TasksTableData({
    required this.idUsuario,
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.prioridad,
    required this.puntosXp,
    required this.estaTerminada,
    this.fechaTope,
    this.creadaEl,
    this.terminadaEl,
    this.color,
    required this.pendienteSincro,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_usuario'] = Variable<String>(idUsuario);
    map['id'] = Variable<String>(id);
    map['titulo'] = Variable<String>(titulo);
    map['subtitulo'] = Variable<String>(subtitulo);
    map['prioridad'] = Variable<String>(prioridad);
    map['puntos_xp'] = Variable<int>(puntosXp);
    map['esta_terminada'] = Variable<bool>(estaTerminada);
    if (!nullToAbsent || fechaTope != null) {
      map['fecha_tope'] = Variable<DateTime>(fechaTope);
    }
    if (!nullToAbsent || creadaEl != null) {
      map['creada_el'] = Variable<DateTime>(creadaEl);
    }
    if (!nullToAbsent || terminadaEl != null) {
      map['terminada_el'] = Variable<DateTime>(terminadaEl);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['pendiente_sincro'] = Variable<bool>(pendienteSincro);
    return map;
  }

  TasksTableCompanion toCompanion(bool nullToAbsent) {
    return TasksTableCompanion(
      idUsuario: Value(idUsuario),
      id: Value(id),
      titulo: Value(titulo),
      subtitulo: Value(subtitulo),
      prioridad: Value(prioridad),
      puntosXp: Value(puntosXp),
      estaTerminada: Value(estaTerminada),
      fechaTope: fechaTope == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaTope),
      creadaEl: creadaEl == null && nullToAbsent
          ? const Value.absent()
          : Value(creadaEl),
      terminadaEl: terminadaEl == null && nullToAbsent
          ? const Value.absent()
          : Value(terminadaEl),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      pendienteSincro: Value(pendienteSincro),
    );
  }

  factory TasksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasksTableData(
      idUsuario: serializer.fromJson<String>(json['idUsuario']),
      id: serializer.fromJson<String>(json['id']),
      titulo: serializer.fromJson<String>(json['titulo']),
      subtitulo: serializer.fromJson<String>(json['subtitulo']),
      prioridad: serializer.fromJson<String>(json['prioridad']),
      puntosXp: serializer.fromJson<int>(json['puntosXp']),
      estaTerminada: serializer.fromJson<bool>(json['estaTerminada']),
      fechaTope: serializer.fromJson<DateTime?>(json['fechaTope']),
      creadaEl: serializer.fromJson<DateTime?>(json['creadaEl']),
      terminadaEl: serializer.fromJson<DateTime?>(json['terminadaEl']),
      color: serializer.fromJson<String?>(json['color']),
      pendienteSincro: serializer.fromJson<bool>(json['pendienteSincro']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idUsuario': serializer.toJson<String>(idUsuario),
      'id': serializer.toJson<String>(id),
      'titulo': serializer.toJson<String>(titulo),
      'subtitulo': serializer.toJson<String>(subtitulo),
      'prioridad': serializer.toJson<String>(prioridad),
      'puntosXp': serializer.toJson<int>(puntosXp),
      'estaTerminada': serializer.toJson<bool>(estaTerminada),
      'fechaTope': serializer.toJson<DateTime?>(fechaTope),
      'creadaEl': serializer.toJson<DateTime?>(creadaEl),
      'terminadaEl': serializer.toJson<DateTime?>(terminadaEl),
      'color': serializer.toJson<String?>(color),
      'pendienteSincro': serializer.toJson<bool>(pendienteSincro),
    };
  }

  TasksTableData copyWith({
    String? idUsuario,
    String? id,
    String? titulo,
    String? subtitulo,
    String? prioridad,
    int? puntosXp,
    bool? estaTerminada,
    Value<DateTime?> fechaTope = const Value.absent(),
    Value<DateTime?> creadaEl = const Value.absent(),
    Value<DateTime?> terminadaEl = const Value.absent(),
    Value<String?> color = const Value.absent(),
    bool? pendienteSincro,
  }) => TasksTableData(
    idUsuario: idUsuario ?? this.idUsuario,
    id: id ?? this.id,
    titulo: titulo ?? this.titulo,
    subtitulo: subtitulo ?? this.subtitulo,
    prioridad: prioridad ?? this.prioridad,
    puntosXp: puntosXp ?? this.puntosXp,
    estaTerminada: estaTerminada ?? this.estaTerminada,
    fechaTope: fechaTope.present ? fechaTope.value : this.fechaTope,
    creadaEl: creadaEl.present ? creadaEl.value : this.creadaEl,
    terminadaEl: terminadaEl.present ? terminadaEl.value : this.terminadaEl,
    color: color.present ? color.value : this.color,
    pendienteSincro: pendienteSincro ?? this.pendienteSincro,
  );
  TasksTableData copyWithCompanion(TasksTableCompanion data) {
    return TasksTableData(
      idUsuario: data.idUsuario.present ? data.idUsuario.value : this.idUsuario,
      id: data.id.present ? data.id.value : this.id,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      subtitulo: data.subtitulo.present ? data.subtitulo.value : this.subtitulo,
      prioridad: data.prioridad.present ? data.prioridad.value : this.prioridad,
      puntosXp: data.puntosXp.present ? data.puntosXp.value : this.puntosXp,
      estaTerminada: data.estaTerminada.present
          ? data.estaTerminada.value
          : this.estaTerminada,
      fechaTope: data.fechaTope.present ? data.fechaTope.value : this.fechaTope,
      creadaEl: data.creadaEl.present ? data.creadaEl.value : this.creadaEl,
      terminadaEl: data.terminadaEl.present
          ? data.terminadaEl.value
          : this.terminadaEl,
      color: data.color.present ? data.color.value : this.color,
      pendienteSincro: data.pendienteSincro.present
          ? data.pendienteSincro.value
          : this.pendienteSincro,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableData(')
          ..write('idUsuario: $idUsuario, ')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('subtitulo: $subtitulo, ')
          ..write('prioridad: $prioridad, ')
          ..write('puntosXp: $puntosXp, ')
          ..write('estaTerminada: $estaTerminada, ')
          ..write('fechaTope: $fechaTope, ')
          ..write('creadaEl: $creadaEl, ')
          ..write('terminadaEl: $terminadaEl, ')
          ..write('color: $color, ')
          ..write('pendienteSincro: $pendienteSincro')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idUsuario,
    id,
    titulo,
    subtitulo,
    prioridad,
    puntosXp,
    estaTerminada,
    fechaTope,
    creadaEl,
    terminadaEl,
    color,
    pendienteSincro,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasksTableData &&
          other.idUsuario == this.idUsuario &&
          other.id == this.id &&
          other.titulo == this.titulo &&
          other.subtitulo == this.subtitulo &&
          other.prioridad == this.prioridad &&
          other.puntosXp == this.puntosXp &&
          other.estaTerminada == this.estaTerminada &&
          other.fechaTope == this.fechaTope &&
          other.creadaEl == this.creadaEl &&
          other.terminadaEl == this.terminadaEl &&
          other.color == this.color &&
          other.pendienteSincro == this.pendienteSincro);
}

class TasksTableCompanion extends UpdateCompanion<TasksTableData> {
  final Value<String> idUsuario;
  final Value<String> id;
  final Value<String> titulo;
  final Value<String> subtitulo;
  final Value<String> prioridad;
  final Value<int> puntosXp;
  final Value<bool> estaTerminada;
  final Value<DateTime?> fechaTope;
  final Value<DateTime?> creadaEl;
  final Value<DateTime?> terminadaEl;
  final Value<String?> color;
  final Value<bool> pendienteSincro;
  final Value<int> rowid;
  const TasksTableCompanion({
    this.idUsuario = const Value.absent(),
    this.id = const Value.absent(),
    this.titulo = const Value.absent(),
    this.subtitulo = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.puntosXp = const Value.absent(),
    this.estaTerminada = const Value.absent(),
    this.fechaTope = const Value.absent(),
    this.creadaEl = const Value.absent(),
    this.terminadaEl = const Value.absent(),
    this.color = const Value.absent(),
    this.pendienteSincro = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksTableCompanion.insert({
    required String idUsuario,
    required String id,
    required String titulo,
    this.subtitulo = const Value.absent(),
    this.prioridad = const Value.absent(),
    this.puntosXp = const Value.absent(),
    this.estaTerminada = const Value.absent(),
    this.fechaTope = const Value.absent(),
    this.creadaEl = const Value.absent(),
    this.terminadaEl = const Value.absent(),
    this.color = const Value.absent(),
    this.pendienteSincro = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idUsuario = Value(idUsuario),
       id = Value(id),
       titulo = Value(titulo);
  static Insertable<TasksTableData> custom({
    Expression<String>? idUsuario,
    Expression<String>? id,
    Expression<String>? titulo,
    Expression<String>? subtitulo,
    Expression<String>? prioridad,
    Expression<int>? puntosXp,
    Expression<bool>? estaTerminada,
    Expression<DateTime>? fechaTope,
    Expression<DateTime>? creadaEl,
    Expression<DateTime>? terminadaEl,
    Expression<String>? color,
    Expression<bool>? pendienteSincro,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idUsuario != null) 'id_usuario': idUsuario,
      if (id != null) 'id': id,
      if (titulo != null) 'titulo': titulo,
      if (subtitulo != null) 'subtitulo': subtitulo,
      if (prioridad != null) 'prioridad': prioridad,
      if (puntosXp != null) 'puntos_xp': puntosXp,
      if (estaTerminada != null) 'esta_terminada': estaTerminada,
      if (fechaTope != null) 'fecha_tope': fechaTope,
      if (creadaEl != null) 'creada_el': creadaEl,
      if (terminadaEl != null) 'terminada_el': terminadaEl,
      if (color != null) 'color': color,
      if (pendienteSincro != null) 'pendiente_sincro': pendienteSincro,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksTableCompanion copyWith({
    Value<String>? idUsuario,
    Value<String>? id,
    Value<String>? titulo,
    Value<String>? subtitulo,
    Value<String>? prioridad,
    Value<int>? puntosXp,
    Value<bool>? estaTerminada,
    Value<DateTime?>? fechaTope,
    Value<DateTime?>? creadaEl,
    Value<DateTime?>? terminadaEl,
    Value<String?>? color,
    Value<bool>? pendienteSincro,
    Value<int>? rowid,
  }) {
    return TasksTableCompanion(
      idUsuario: idUsuario ?? this.idUsuario,
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      subtitulo: subtitulo ?? this.subtitulo,
      prioridad: prioridad ?? this.prioridad,
      puntosXp: puntosXp ?? this.puntosXp,
      estaTerminada: estaTerminada ?? this.estaTerminada,
      fechaTope: fechaTope ?? this.fechaTope,
      creadaEl: creadaEl ?? this.creadaEl,
      terminadaEl: terminadaEl ?? this.terminadaEl,
      color: color ?? this.color,
      pendienteSincro: pendienteSincro ?? this.pendienteSincro,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idUsuario.present) {
      map['id_usuario'] = Variable<String>(idUsuario.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (subtitulo.present) {
      map['subtitulo'] = Variable<String>(subtitulo.value);
    }
    if (prioridad.present) {
      map['prioridad'] = Variable<String>(prioridad.value);
    }
    if (puntosXp.present) {
      map['puntos_xp'] = Variable<int>(puntosXp.value);
    }
    if (estaTerminada.present) {
      map['esta_terminada'] = Variable<bool>(estaTerminada.value);
    }
    if (fechaTope.present) {
      map['fecha_tope'] = Variable<DateTime>(fechaTope.value);
    }
    if (creadaEl.present) {
      map['creada_el'] = Variable<DateTime>(creadaEl.value);
    }
    if (terminadaEl.present) {
      map['terminada_el'] = Variable<DateTime>(terminadaEl.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (pendienteSincro.present) {
      map['pendiente_sincro'] = Variable<bool>(pendienteSincro.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableCompanion(')
          ..write('idUsuario: $idUsuario, ')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('subtitulo: $subtitulo, ')
          ..write('prioridad: $prioridad, ')
          ..write('puntosXp: $puntosXp, ')
          ..write('estaTerminada: $estaTerminada, ')
          ..write('fechaTope: $fechaTope, ')
          ..write('creadaEl: $creadaEl, ')
          ..write('terminadaEl: $terminadaEl, ')
          ..write('color: $color, ')
          ..write('pendienteSincro: $pendienteSincro, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTableTable extends AccountsTable
    with TableInfo<$AccountsTableTable, AccountsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idUsuarioMeta = const VerificationMeta(
    'idUsuario',
  );
  @override
  late final GeneratedColumn<String> idUsuario = GeneratedColumn<String>(
    'id_usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorColorMeta = const VerificationMeta(
    'valorColor',
  );
  @override
  late final GeneratedColumn<int> valorColor = GeneratedColumn<int>(
    'valor_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indiceColorMeta = const VerificationMeta(
    'indiceColor',
  );
  @override
  late final GeneratedColumn<int> indiceColor = GeneratedColumn<int>(
    'indice_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _tokenAccesoMeta = const VerificationMeta(
    'tokenAcceso',
  );
  @override
  late final GeneratedColumn<String> tokenAcceso = GeneratedColumn<String>(
    'token_acceso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _expiracionTokenMeta = const VerificationMeta(
    'expiracionToken',
  );
  @override
  late final GeneratedColumn<DateTime> expiracionToken =
      GeneratedColumn<DateTime>(
        'expiracion_token',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _conectadaElMeta = const VerificationMeta(
    'conectadaEl',
  );
  @override
  late final GeneratedColumn<DateTime> conectadaEl = GeneratedColumn<DateTime>(
    'conectada_el',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idUsuario,
    email,
    valorColor,
    indiceColor,
    tokenAcceso,
    expiracionToken,
    conectadaEl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_usuario')) {
      context.handle(
        _idUsuarioMeta,
        idUsuario.isAcceptableOrUnknown(data['id_usuario']!, _idUsuarioMeta),
      );
    } else if (isInserting) {
      context.missing(_idUsuarioMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('valor_color')) {
      context.handle(
        _valorColorMeta,
        valorColor.isAcceptableOrUnknown(data['valor_color']!, _valorColorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorColorMeta);
    }
    if (data.containsKey('indice_color')) {
      context.handle(
        _indiceColorMeta,
        indiceColor.isAcceptableOrUnknown(
          data['indice_color']!,
          _indiceColorMeta,
        ),
      );
    }
    if (data.containsKey('token_acceso')) {
      context.handle(
        _tokenAccesoMeta,
        tokenAcceso.isAcceptableOrUnknown(
          data['token_acceso']!,
          _tokenAccesoMeta,
        ),
      );
    }
    if (data.containsKey('expiracion_token')) {
      context.handle(
        _expiracionTokenMeta,
        expiracionToken.isAcceptableOrUnknown(
          data['expiracion_token']!,
          _expiracionTokenMeta,
        ),
      );
    }
    if (data.containsKey('conectada_el')) {
      context.handle(
        _conectadaElMeta,
        conectadaEl.isAcceptableOrUnknown(
          data['conectada_el']!,
          _conectadaElMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {email, idUsuario};
  @override
  AccountsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsTableData(
      idUsuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_usuario'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      valorColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}valor_color'],
      )!,
      indiceColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indice_color'],
      )!,
      tokenAcceso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_acceso'],
      )!,
      expiracionToken: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiracion_token'],
      ),
      conectadaEl: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}conectada_el'],
      ),
    );
  }

  @override
  $AccountsTableTable createAlias(String alias) {
    return $AccountsTableTable(attachedDatabase, alias);
  }
}

class AccountsTableData extends DataClass
    implements Insertable<AccountsTableData> {
  final String idUsuario;
  final String email;
  final int valorColor;
  final int indiceColor;
  final String tokenAcceso;
  final DateTime? expiracionToken;
  final DateTime? conectadaEl;
  const AccountsTableData({
    required this.idUsuario,
    required this.email,
    required this.valorColor,
    required this.indiceColor,
    required this.tokenAcceso,
    this.expiracionToken,
    this.conectadaEl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_usuario'] = Variable<String>(idUsuario);
    map['email'] = Variable<String>(email);
    map['valor_color'] = Variable<int>(valorColor);
    map['indice_color'] = Variable<int>(indiceColor);
    map['token_acceso'] = Variable<String>(tokenAcceso);
    if (!nullToAbsent || expiracionToken != null) {
      map['expiracion_token'] = Variable<DateTime>(expiracionToken);
    }
    if (!nullToAbsent || conectadaEl != null) {
      map['conectada_el'] = Variable<DateTime>(conectadaEl);
    }
    return map;
  }

  AccountsTableCompanion toCompanion(bool nullToAbsent) {
    return AccountsTableCompanion(
      idUsuario: Value(idUsuario),
      email: Value(email),
      valorColor: Value(valorColor),
      indiceColor: Value(indiceColor),
      tokenAcceso: Value(tokenAcceso),
      expiracionToken: expiracionToken == null && nullToAbsent
          ? const Value.absent()
          : Value(expiracionToken),
      conectadaEl: conectadaEl == null && nullToAbsent
          ? const Value.absent()
          : Value(conectadaEl),
    );
  }

  factory AccountsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsTableData(
      idUsuario: serializer.fromJson<String>(json['idUsuario']),
      email: serializer.fromJson<String>(json['email']),
      valorColor: serializer.fromJson<int>(json['valorColor']),
      indiceColor: serializer.fromJson<int>(json['indiceColor']),
      tokenAcceso: serializer.fromJson<String>(json['tokenAcceso']),
      expiracionToken: serializer.fromJson<DateTime?>(json['expiracionToken']),
      conectadaEl: serializer.fromJson<DateTime?>(json['conectadaEl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idUsuario': serializer.toJson<String>(idUsuario),
      'email': serializer.toJson<String>(email),
      'valorColor': serializer.toJson<int>(valorColor),
      'indiceColor': serializer.toJson<int>(indiceColor),
      'tokenAcceso': serializer.toJson<String>(tokenAcceso),
      'expiracionToken': serializer.toJson<DateTime?>(expiracionToken),
      'conectadaEl': serializer.toJson<DateTime?>(conectadaEl),
    };
  }

  AccountsTableData copyWith({
    String? idUsuario,
    String? email,
    int? valorColor,
    int? indiceColor,
    String? tokenAcceso,
    Value<DateTime?> expiracionToken = const Value.absent(),
    Value<DateTime?> conectadaEl = const Value.absent(),
  }) => AccountsTableData(
    idUsuario: idUsuario ?? this.idUsuario,
    email: email ?? this.email,
    valorColor: valorColor ?? this.valorColor,
    indiceColor: indiceColor ?? this.indiceColor,
    tokenAcceso: tokenAcceso ?? this.tokenAcceso,
    expiracionToken: expiracionToken.present
        ? expiracionToken.value
        : this.expiracionToken,
    conectadaEl: conectadaEl.present ? conectadaEl.value : this.conectadaEl,
  );
  AccountsTableData copyWithCompanion(AccountsTableCompanion data) {
    return AccountsTableData(
      idUsuario: data.idUsuario.present ? data.idUsuario.value : this.idUsuario,
      email: data.email.present ? data.email.value : this.email,
      valorColor: data.valorColor.present
          ? data.valorColor.value
          : this.valorColor,
      indiceColor: data.indiceColor.present
          ? data.indiceColor.value
          : this.indiceColor,
      tokenAcceso: data.tokenAcceso.present
          ? data.tokenAcceso.value
          : this.tokenAcceso,
      expiracionToken: data.expiracionToken.present
          ? data.expiracionToken.value
          : this.expiracionToken,
      conectadaEl: data.conectadaEl.present
          ? data.conectadaEl.value
          : this.conectadaEl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableData(')
          ..write('idUsuario: $idUsuario, ')
          ..write('email: $email, ')
          ..write('valorColor: $valorColor, ')
          ..write('indiceColor: $indiceColor, ')
          ..write('tokenAcceso: $tokenAcceso, ')
          ..write('expiracionToken: $expiracionToken, ')
          ..write('conectadaEl: $conectadaEl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idUsuario,
    email,
    valorColor,
    indiceColor,
    tokenAcceso,
    expiracionToken,
    conectadaEl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsTableData &&
          other.idUsuario == this.idUsuario &&
          other.email == this.email &&
          other.valorColor == this.valorColor &&
          other.indiceColor == this.indiceColor &&
          other.tokenAcceso == this.tokenAcceso &&
          other.expiracionToken == this.expiracionToken &&
          other.conectadaEl == this.conectadaEl);
}

class AccountsTableCompanion extends UpdateCompanion<AccountsTableData> {
  final Value<String> idUsuario;
  final Value<String> email;
  final Value<int> valorColor;
  final Value<int> indiceColor;
  final Value<String> tokenAcceso;
  final Value<DateTime?> expiracionToken;
  final Value<DateTime?> conectadaEl;
  final Value<int> rowid;
  const AccountsTableCompanion({
    this.idUsuario = const Value.absent(),
    this.email = const Value.absent(),
    this.valorColor = const Value.absent(),
    this.indiceColor = const Value.absent(),
    this.tokenAcceso = const Value.absent(),
    this.expiracionToken = const Value.absent(),
    this.conectadaEl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsTableCompanion.insert({
    required String idUsuario,
    required String email,
    required int valorColor,
    this.indiceColor = const Value.absent(),
    this.tokenAcceso = const Value.absent(),
    this.expiracionToken = const Value.absent(),
    this.conectadaEl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idUsuario = Value(idUsuario),
       email = Value(email),
       valorColor = Value(valorColor);
  static Insertable<AccountsTableData> custom({
    Expression<String>? idUsuario,
    Expression<String>? email,
    Expression<int>? valorColor,
    Expression<int>? indiceColor,
    Expression<String>? tokenAcceso,
    Expression<DateTime>? expiracionToken,
    Expression<DateTime>? conectadaEl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idUsuario != null) 'id_usuario': idUsuario,
      if (email != null) 'email': email,
      if (valorColor != null) 'valor_color': valorColor,
      if (indiceColor != null) 'indice_color': indiceColor,
      if (tokenAcceso != null) 'token_acceso': tokenAcceso,
      if (expiracionToken != null) 'expiracion_token': expiracionToken,
      if (conectadaEl != null) 'conectada_el': conectadaEl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsTableCompanion copyWith({
    Value<String>? idUsuario,
    Value<String>? email,
    Value<int>? valorColor,
    Value<int>? indiceColor,
    Value<String>? tokenAcceso,
    Value<DateTime?>? expiracionToken,
    Value<DateTime?>? conectadaEl,
    Value<int>? rowid,
  }) {
    return AccountsTableCompanion(
      idUsuario: idUsuario ?? this.idUsuario,
      email: email ?? this.email,
      valorColor: valorColor ?? this.valorColor,
      indiceColor: indiceColor ?? this.indiceColor,
      tokenAcceso: tokenAcceso ?? this.tokenAcceso,
      expiracionToken: expiracionToken ?? this.expiracionToken,
      conectadaEl: conectadaEl ?? this.conectadaEl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idUsuario.present) {
      map['id_usuario'] = Variable<String>(idUsuario.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (valorColor.present) {
      map['valor_color'] = Variable<int>(valorColor.value);
    }
    if (indiceColor.present) {
      map['indice_color'] = Variable<int>(indiceColor.value);
    }
    if (tokenAcceso.present) {
      map['token_acceso'] = Variable<String>(tokenAcceso.value);
    }
    if (expiracionToken.present) {
      map['expiracion_token'] = Variable<DateTime>(expiracionToken.value);
    }
    if (conectadaEl.present) {
      map['conectada_el'] = Variable<DateTime>(conectadaEl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableCompanion(')
          ..write('idUsuario: $idUsuario, ')
          ..write('email: $email, ')
          ..write('valorColor: $valorColor, ')
          ..write('indiceColor: $indiceColor, ')
          ..write('tokenAcceso: $tokenAcceso, ')
          ..write('expiracionToken: $expiracionToken, ')
          ..write('conectadaEl: $conectadaEl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarsTableTable extends CalendarsTable
    with TableInfo<$CalendarsTableTable, CalendarsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idUsuarioMeta = const VerificationMeta(
    'idUsuario',
  );
  @override
  late final GeneratedColumn<String> idUsuario = GeneratedColumn<String>(
    'id_usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailCuentaMeta = const VerificationMeta(
    'emailCuenta',
  );
  @override
  late final GeneratedColumn<String> emailCuenta = GeneratedColumn<String>(
    'email_cuenta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resumenMeta = const VerificationMeta(
    'resumen',
  );
  @override
  late final GeneratedColumn<String> resumen = GeneratedColumn<String>(
    'resumen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Calendario'),
  );
  static const VerificationMeta _colorFondoMeta = const VerificationMeta(
    'colorFondo',
  );
  @override
  late final GeneratedColumn<String> colorFondo = GeneratedColumn<String>(
    'color_fondo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolAccesoMeta = const VerificationMeta(
    'rolAcceso',
  );
  @override
  late final GeneratedColumn<String> rolAcceso = GeneratedColumn<String>(
    'rol_acceso',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('reader'),
  );
  static const VerificationMeta _esVisibleMeta = const VerificationMeta(
    'esVisible',
  );
  @override
  late final GeneratedColumn<bool> esVisible = GeneratedColumn<bool>(
    'es_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    idUsuario,
    id,
    emailCuenta,
    resumen,
    colorFondo,
    rolAcceso,
    esVisible,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendars_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_usuario')) {
      context.handle(
        _idUsuarioMeta,
        idUsuario.isAcceptableOrUnknown(data['id_usuario']!, _idUsuarioMeta),
      );
    } else if (isInserting) {
      context.missing(_idUsuarioMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email_cuenta')) {
      context.handle(
        _emailCuentaMeta,
        emailCuenta.isAcceptableOrUnknown(
          data['email_cuenta']!,
          _emailCuentaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_emailCuentaMeta);
    }
    if (data.containsKey('resumen')) {
      context.handle(
        _resumenMeta,
        resumen.isAcceptableOrUnknown(data['resumen']!, _resumenMeta),
      );
    }
    if (data.containsKey('color_fondo')) {
      context.handle(
        _colorFondoMeta,
        colorFondo.isAcceptableOrUnknown(data['color_fondo']!, _colorFondoMeta),
      );
    }
    if (data.containsKey('rol_acceso')) {
      context.handle(
        _rolAccesoMeta,
        rolAcceso.isAcceptableOrUnknown(data['rol_acceso']!, _rolAccesoMeta),
      );
    }
    if (data.containsKey('es_visible')) {
      context.handle(
        _esVisibleMeta,
        esVisible.isAcceptableOrUnknown(data['es_visible']!, _esVisibleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, emailCuenta, idUsuario};
  @override
  CalendarsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarsTableData(
      idUsuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_usuario'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      emailCuenta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_cuenta'],
      )!,
      resumen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resumen'],
      )!,
      colorFondo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_fondo'],
      ),
      rolAcceso: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol_acceso'],
      )!,
      esVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_visible'],
      )!,
    );
  }

  @override
  $CalendarsTableTable createAlias(String alias) {
    return $CalendarsTableTable(attachedDatabase, alias);
  }
}

class CalendarsTableData extends DataClass
    implements Insertable<CalendarsTableData> {
  final String idUsuario;
  final String id;
  final String emailCuenta;
  final String resumen;
  final String? colorFondo;
  final String rolAcceso;
  final bool esVisible;
  const CalendarsTableData({
    required this.idUsuario,
    required this.id,
    required this.emailCuenta,
    required this.resumen,
    this.colorFondo,
    required this.rolAcceso,
    required this.esVisible,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_usuario'] = Variable<String>(idUsuario);
    map['id'] = Variable<String>(id);
    map['email_cuenta'] = Variable<String>(emailCuenta);
    map['resumen'] = Variable<String>(resumen);
    if (!nullToAbsent || colorFondo != null) {
      map['color_fondo'] = Variable<String>(colorFondo);
    }
    map['rol_acceso'] = Variable<String>(rolAcceso);
    map['es_visible'] = Variable<bool>(esVisible);
    return map;
  }

  CalendarsTableCompanion toCompanion(bool nullToAbsent) {
    return CalendarsTableCompanion(
      idUsuario: Value(idUsuario),
      id: Value(id),
      emailCuenta: Value(emailCuenta),
      resumen: Value(resumen),
      colorFondo: colorFondo == null && nullToAbsent
          ? const Value.absent()
          : Value(colorFondo),
      rolAcceso: Value(rolAcceso),
      esVisible: Value(esVisible),
    );
  }

  factory CalendarsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarsTableData(
      idUsuario: serializer.fromJson<String>(json['idUsuario']),
      id: serializer.fromJson<String>(json['id']),
      emailCuenta: serializer.fromJson<String>(json['emailCuenta']),
      resumen: serializer.fromJson<String>(json['resumen']),
      colorFondo: serializer.fromJson<String?>(json['colorFondo']),
      rolAcceso: serializer.fromJson<String>(json['rolAcceso']),
      esVisible: serializer.fromJson<bool>(json['esVisible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idUsuario': serializer.toJson<String>(idUsuario),
      'id': serializer.toJson<String>(id),
      'emailCuenta': serializer.toJson<String>(emailCuenta),
      'resumen': serializer.toJson<String>(resumen),
      'colorFondo': serializer.toJson<String?>(colorFondo),
      'rolAcceso': serializer.toJson<String>(rolAcceso),
      'esVisible': serializer.toJson<bool>(esVisible),
    };
  }

  CalendarsTableData copyWith({
    String? idUsuario,
    String? id,
    String? emailCuenta,
    String? resumen,
    Value<String?> colorFondo = const Value.absent(),
    String? rolAcceso,
    bool? esVisible,
  }) => CalendarsTableData(
    idUsuario: idUsuario ?? this.idUsuario,
    id: id ?? this.id,
    emailCuenta: emailCuenta ?? this.emailCuenta,
    resumen: resumen ?? this.resumen,
    colorFondo: colorFondo.present ? colorFondo.value : this.colorFondo,
    rolAcceso: rolAcceso ?? this.rolAcceso,
    esVisible: esVisible ?? this.esVisible,
  );
  CalendarsTableData copyWithCompanion(CalendarsTableCompanion data) {
    return CalendarsTableData(
      idUsuario: data.idUsuario.present ? data.idUsuario.value : this.idUsuario,
      id: data.id.present ? data.id.value : this.id,
      emailCuenta: data.emailCuenta.present
          ? data.emailCuenta.value
          : this.emailCuenta,
      resumen: data.resumen.present ? data.resumen.value : this.resumen,
      colorFondo: data.colorFondo.present
          ? data.colorFondo.value
          : this.colorFondo,
      rolAcceso: data.rolAcceso.present ? data.rolAcceso.value : this.rolAcceso,
      esVisible: data.esVisible.present ? data.esVisible.value : this.esVisible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarsTableData(')
          ..write('idUsuario: $idUsuario, ')
          ..write('id: $id, ')
          ..write('emailCuenta: $emailCuenta, ')
          ..write('resumen: $resumen, ')
          ..write('colorFondo: $colorFondo, ')
          ..write('rolAcceso: $rolAcceso, ')
          ..write('esVisible: $esVisible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idUsuario,
    id,
    emailCuenta,
    resumen,
    colorFondo,
    rolAcceso,
    esVisible,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarsTableData &&
          other.idUsuario == this.idUsuario &&
          other.id == this.id &&
          other.emailCuenta == this.emailCuenta &&
          other.resumen == this.resumen &&
          other.colorFondo == this.colorFondo &&
          other.rolAcceso == this.rolAcceso &&
          other.esVisible == this.esVisible);
}

class CalendarsTableCompanion extends UpdateCompanion<CalendarsTableData> {
  final Value<String> idUsuario;
  final Value<String> id;
  final Value<String> emailCuenta;
  final Value<String> resumen;
  final Value<String?> colorFondo;
  final Value<String> rolAcceso;
  final Value<bool> esVisible;
  final Value<int> rowid;
  const CalendarsTableCompanion({
    this.idUsuario = const Value.absent(),
    this.id = const Value.absent(),
    this.emailCuenta = const Value.absent(),
    this.resumen = const Value.absent(),
    this.colorFondo = const Value.absent(),
    this.rolAcceso = const Value.absent(),
    this.esVisible = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarsTableCompanion.insert({
    required String idUsuario,
    required String id,
    required String emailCuenta,
    this.resumen = const Value.absent(),
    this.colorFondo = const Value.absent(),
    this.rolAcceso = const Value.absent(),
    this.esVisible = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idUsuario = Value(idUsuario),
       id = Value(id),
       emailCuenta = Value(emailCuenta);
  static Insertable<CalendarsTableData> custom({
    Expression<String>? idUsuario,
    Expression<String>? id,
    Expression<String>? emailCuenta,
    Expression<String>? resumen,
    Expression<String>? colorFondo,
    Expression<String>? rolAcceso,
    Expression<bool>? esVisible,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idUsuario != null) 'id_usuario': idUsuario,
      if (id != null) 'id': id,
      if (emailCuenta != null) 'email_cuenta': emailCuenta,
      if (resumen != null) 'resumen': resumen,
      if (colorFondo != null) 'color_fondo': colorFondo,
      if (rolAcceso != null) 'rol_acceso': rolAcceso,
      if (esVisible != null) 'es_visible': esVisible,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarsTableCompanion copyWith({
    Value<String>? idUsuario,
    Value<String>? id,
    Value<String>? emailCuenta,
    Value<String>? resumen,
    Value<String?>? colorFondo,
    Value<String>? rolAcceso,
    Value<bool>? esVisible,
    Value<int>? rowid,
  }) {
    return CalendarsTableCompanion(
      idUsuario: idUsuario ?? this.idUsuario,
      id: id ?? this.id,
      emailCuenta: emailCuenta ?? this.emailCuenta,
      resumen: resumen ?? this.resumen,
      colorFondo: colorFondo ?? this.colorFondo,
      rolAcceso: rolAcceso ?? this.rolAcceso,
      esVisible: esVisible ?? this.esVisible,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idUsuario.present) {
      map['id_usuario'] = Variable<String>(idUsuario.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (emailCuenta.present) {
      map['email_cuenta'] = Variable<String>(emailCuenta.value);
    }
    if (resumen.present) {
      map['resumen'] = Variable<String>(resumen.value);
    }
    if (colorFondo.present) {
      map['color_fondo'] = Variable<String>(colorFondo.value);
    }
    if (rolAcceso.present) {
      map['rol_acceso'] = Variable<String>(rolAcceso.value);
    }
    if (esVisible.present) {
      map['es_visible'] = Variable<bool>(esVisible.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarsTableCompanion(')
          ..write('idUsuario: $idUsuario, ')
          ..write('id: $id, ')
          ..write('emailCuenta: $emailCuenta, ')
          ..write('resumen: $resumen, ')
          ..write('colorFondo: $colorFondo, ')
          ..write('rolAcceso: $rolAcceso, ')
          ..write('esVisible: $esVisible, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTableTable tasksTable = $TasksTableTable(this);
  late final $AccountsTableTable accountsTable = $AccountsTableTable(this);
  late final $CalendarsTableTable calendarsTable = $CalendarsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasksTable,
    accountsTable,
    calendarsTable,
  ];
}

typedef $$TasksTableTableCreateCompanionBuilder =
    TasksTableCompanion Function({
      required String idUsuario,
      required String id,
      required String titulo,
      Value<String> subtitulo,
      Value<String> prioridad,
      Value<int> puntosXp,
      Value<bool> estaTerminada,
      Value<DateTime?> fechaTope,
      Value<DateTime?> creadaEl,
      Value<DateTime?> terminadaEl,
      Value<String?> color,
      Value<bool> pendienteSincro,
      Value<int> rowid,
    });
typedef $$TasksTableTableUpdateCompanionBuilder =
    TasksTableCompanion Function({
      Value<String> idUsuario,
      Value<String> id,
      Value<String> titulo,
      Value<String> subtitulo,
      Value<String> prioridad,
      Value<int> puntosXp,
      Value<bool> estaTerminada,
      Value<DateTime?> fechaTope,
      Value<DateTime?> creadaEl,
      Value<DateTime?> terminadaEl,
      Value<String?> color,
      Value<bool> pendienteSincro,
      Value<int> rowid,
    });

class $$TasksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idUsuario => $composableBuilder(
    column: $table.idUsuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitulo => $composableBuilder(
    column: $table.subtitulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get puntosXp => $composableBuilder(
    column: $table.puntosXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estaTerminada => $composableBuilder(
    column: $table.estaTerminada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaTope => $composableBuilder(
    column: $table.fechaTope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadaEl => $composableBuilder(
    column: $table.creadaEl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get terminadaEl => $composableBuilder(
    column: $table.terminadaEl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendienteSincro => $composableBuilder(
    column: $table.pendienteSincro,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idUsuario => $composableBuilder(
    column: $table.idUsuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitulo => $composableBuilder(
    column: $table.subtitulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prioridad => $composableBuilder(
    column: $table.prioridad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get puntosXp => $composableBuilder(
    column: $table.puntosXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estaTerminada => $composableBuilder(
    column: $table.estaTerminada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaTope => $composableBuilder(
    column: $table.fechaTope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadaEl => $composableBuilder(
    column: $table.creadaEl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get terminadaEl => $composableBuilder(
    column: $table.terminadaEl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendienteSincro => $composableBuilder(
    column: $table.pendienteSincro,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idUsuario =>
      $composableBuilder(column: $table.idUsuario, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get subtitulo =>
      $composableBuilder(column: $table.subtitulo, builder: (column) => column);

  GeneratedColumn<String> get prioridad =>
      $composableBuilder(column: $table.prioridad, builder: (column) => column);

  GeneratedColumn<int> get puntosXp =>
      $composableBuilder(column: $table.puntosXp, builder: (column) => column);

  GeneratedColumn<bool> get estaTerminada => $composableBuilder(
    column: $table.estaTerminada,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaTope =>
      $composableBuilder(column: $table.fechaTope, builder: (column) => column);

  GeneratedColumn<DateTime> get creadaEl =>
      $composableBuilder(column: $table.creadaEl, builder: (column) => column);

  GeneratedColumn<DateTime> get terminadaEl => $composableBuilder(
    column: $table.terminadaEl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get pendienteSincro => $composableBuilder(
    column: $table.pendienteSincro,
    builder: (column) => column,
  );
}

class $$TasksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTableTable,
          TasksTableData,
          $$TasksTableTableFilterComposer,
          $$TasksTableTableOrderingComposer,
          $$TasksTableTableAnnotationComposer,
          $$TasksTableTableCreateCompanionBuilder,
          $$TasksTableTableUpdateCompanionBuilder,
          (
            TasksTableData,
            BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
          ),
          TasksTableData,
          PrefetchHooks Function()
        > {
  $$TasksTableTableTableManager(_$AppDatabase db, $TasksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idUsuario = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String> subtitulo = const Value.absent(),
                Value<String> prioridad = const Value.absent(),
                Value<int> puntosXp = const Value.absent(),
                Value<bool> estaTerminada = const Value.absent(),
                Value<DateTime?> fechaTope = const Value.absent(),
                Value<DateTime?> creadaEl = const Value.absent(),
                Value<DateTime?> terminadaEl = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> pendienteSincro = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksTableCompanion(
                idUsuario: idUsuario,
                id: id,
                titulo: titulo,
                subtitulo: subtitulo,
                prioridad: prioridad,
                puntosXp: puntosXp,
                estaTerminada: estaTerminada,
                fechaTope: fechaTope,
                creadaEl: creadaEl,
                terminadaEl: terminadaEl,
                color: color,
                pendienteSincro: pendienteSincro,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idUsuario,
                required String id,
                required String titulo,
                Value<String> subtitulo = const Value.absent(),
                Value<String> prioridad = const Value.absent(),
                Value<int> puntosXp = const Value.absent(),
                Value<bool> estaTerminada = const Value.absent(),
                Value<DateTime?> fechaTope = const Value.absent(),
                Value<DateTime?> creadaEl = const Value.absent(),
                Value<DateTime?> terminadaEl = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> pendienteSincro = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksTableCompanion.insert(
                idUsuario: idUsuario,
                id: id,
                titulo: titulo,
                subtitulo: subtitulo,
                prioridad: prioridad,
                puntosXp: puntosXp,
                estaTerminada: estaTerminada,
                fechaTope: fechaTope,
                creadaEl: creadaEl,
                terminadaEl: terminadaEl,
                color: color,
                pendienteSincro: pendienteSincro,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTableTable,
      TasksTableData,
      $$TasksTableTableFilterComposer,
      $$TasksTableTableOrderingComposer,
      $$TasksTableTableAnnotationComposer,
      $$TasksTableTableCreateCompanionBuilder,
      $$TasksTableTableUpdateCompanionBuilder,
      (
        TasksTableData,
        BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
      ),
      TasksTableData,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableTableCreateCompanionBuilder =
    AccountsTableCompanion Function({
      required String idUsuario,
      required String email,
      required int valorColor,
      Value<int> indiceColor,
      Value<String> tokenAcceso,
      Value<DateTime?> expiracionToken,
      Value<DateTime?> conectadaEl,
      Value<int> rowid,
    });
typedef $$AccountsTableTableUpdateCompanionBuilder =
    AccountsTableCompanion Function({
      Value<String> idUsuario,
      Value<String> email,
      Value<int> valorColor,
      Value<int> indiceColor,
      Value<String> tokenAcceso,
      Value<DateTime?> expiracionToken,
      Value<DateTime?> conectadaEl,
      Value<int> rowid,
    });

class $$AccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idUsuario => $composableBuilder(
    column: $table.idUsuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valorColor => $composableBuilder(
    column: $table.valorColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indiceColor => $composableBuilder(
    column: $table.indiceColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenAcceso => $composableBuilder(
    column: $table.tokenAcceso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiracionToken => $composableBuilder(
    column: $table.expiracionToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get conectadaEl => $composableBuilder(
    column: $table.conectadaEl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idUsuario => $composableBuilder(
    column: $table.idUsuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valorColor => $composableBuilder(
    column: $table.valorColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indiceColor => $composableBuilder(
    column: $table.indiceColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenAcceso => $composableBuilder(
    column: $table.tokenAcceso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiracionToken => $composableBuilder(
    column: $table.expiracionToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get conectadaEl => $composableBuilder(
    column: $table.conectadaEl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idUsuario =>
      $composableBuilder(column: $table.idUsuario, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get valorColor => $composableBuilder(
    column: $table.valorColor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get indiceColor => $composableBuilder(
    column: $table.indiceColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tokenAcceso => $composableBuilder(
    column: $table.tokenAcceso,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiracionToken => $composableBuilder(
    column: $table.expiracionToken,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get conectadaEl => $composableBuilder(
    column: $table.conectadaEl,
    builder: (column) => column,
  );
}

class $$AccountsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTableTable,
          AccountsTableData,
          $$AccountsTableTableFilterComposer,
          $$AccountsTableTableOrderingComposer,
          $$AccountsTableTableAnnotationComposer,
          $$AccountsTableTableCreateCompanionBuilder,
          $$AccountsTableTableUpdateCompanionBuilder,
          (
            AccountsTableData,
            BaseReferences<
              _$AppDatabase,
              $AccountsTableTable,
              AccountsTableData
            >,
          ),
          AccountsTableData,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableTableManager(_$AppDatabase db, $AccountsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idUsuario = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int> valorColor = const Value.absent(),
                Value<int> indiceColor = const Value.absent(),
                Value<String> tokenAcceso = const Value.absent(),
                Value<DateTime?> expiracionToken = const Value.absent(),
                Value<DateTime?> conectadaEl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsTableCompanion(
                idUsuario: idUsuario,
                email: email,
                valorColor: valorColor,
                indiceColor: indiceColor,
                tokenAcceso: tokenAcceso,
                expiracionToken: expiracionToken,
                conectadaEl: conectadaEl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idUsuario,
                required String email,
                required int valorColor,
                Value<int> indiceColor = const Value.absent(),
                Value<String> tokenAcceso = const Value.absent(),
                Value<DateTime?> expiracionToken = const Value.absent(),
                Value<DateTime?> conectadaEl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsTableCompanion.insert(
                idUsuario: idUsuario,
                email: email,
                valorColor: valorColor,
                indiceColor: indiceColor,
                tokenAcceso: tokenAcceso,
                expiracionToken: expiracionToken,
                conectadaEl: conectadaEl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTableTable,
      AccountsTableData,
      $$AccountsTableTableFilterComposer,
      $$AccountsTableTableOrderingComposer,
      $$AccountsTableTableAnnotationComposer,
      $$AccountsTableTableCreateCompanionBuilder,
      $$AccountsTableTableUpdateCompanionBuilder,
      (
        AccountsTableData,
        BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>,
      ),
      AccountsTableData,
      PrefetchHooks Function()
    >;
typedef $$CalendarsTableTableCreateCompanionBuilder =
    CalendarsTableCompanion Function({
      required String idUsuario,
      required String id,
      required String emailCuenta,
      Value<String> resumen,
      Value<String?> colorFondo,
      Value<String> rolAcceso,
      Value<bool> esVisible,
      Value<int> rowid,
    });
typedef $$CalendarsTableTableUpdateCompanionBuilder =
    CalendarsTableCompanion Function({
      Value<String> idUsuario,
      Value<String> id,
      Value<String> emailCuenta,
      Value<String> resumen,
      Value<String?> colorFondo,
      Value<String> rolAcceso,
      Value<bool> esVisible,
      Value<int> rowid,
    });

class $$CalendarsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarsTableTable> {
  $$CalendarsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idUsuario => $composableBuilder(
    column: $table.idUsuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailCuenta => $composableBuilder(
    column: $table.emailCuenta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumen => $composableBuilder(
    column: $table.resumen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorFondo => $composableBuilder(
    column: $table.colorFondo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolAcceso => $composableBuilder(
    column: $table.rolAcceso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esVisible => $composableBuilder(
    column: $table.esVisible,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarsTableTable> {
  $$CalendarsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idUsuario => $composableBuilder(
    column: $table.idUsuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailCuenta => $composableBuilder(
    column: $table.emailCuenta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumen => $composableBuilder(
    column: $table.resumen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorFondo => $composableBuilder(
    column: $table.colorFondo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolAcceso => $composableBuilder(
    column: $table.rolAcceso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esVisible => $composableBuilder(
    column: $table.esVisible,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarsTableTable> {
  $$CalendarsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idUsuario =>
      $composableBuilder(column: $table.idUsuario, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get emailCuenta => $composableBuilder(
    column: $table.emailCuenta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumen =>
      $composableBuilder(column: $table.resumen, builder: (column) => column);

  GeneratedColumn<String> get colorFondo => $composableBuilder(
    column: $table.colorFondo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rolAcceso =>
      $composableBuilder(column: $table.rolAcceso, builder: (column) => column);

  GeneratedColumn<bool> get esVisible =>
      $composableBuilder(column: $table.esVisible, builder: (column) => column);
}

class $$CalendarsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarsTableTable,
          CalendarsTableData,
          $$CalendarsTableTableFilterComposer,
          $$CalendarsTableTableOrderingComposer,
          $$CalendarsTableTableAnnotationComposer,
          $$CalendarsTableTableCreateCompanionBuilder,
          $$CalendarsTableTableUpdateCompanionBuilder,
          (
            CalendarsTableData,
            BaseReferences<
              _$AppDatabase,
              $CalendarsTableTable,
              CalendarsTableData
            >,
          ),
          CalendarsTableData,
          PrefetchHooks Function()
        > {
  $$CalendarsTableTableTableManager(
    _$AppDatabase db,
    $CalendarsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idUsuario = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> emailCuenta = const Value.absent(),
                Value<String> resumen = const Value.absent(),
                Value<String?> colorFondo = const Value.absent(),
                Value<String> rolAcceso = const Value.absent(),
                Value<bool> esVisible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsTableCompanion(
                idUsuario: idUsuario,
                id: id,
                emailCuenta: emailCuenta,
                resumen: resumen,
                colorFondo: colorFondo,
                rolAcceso: rolAcceso,
                esVisible: esVisible,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idUsuario,
                required String id,
                required String emailCuenta,
                Value<String> resumen = const Value.absent(),
                Value<String?> colorFondo = const Value.absent(),
                Value<String> rolAcceso = const Value.absent(),
                Value<bool> esVisible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarsTableCompanion.insert(
                idUsuario: idUsuario,
                id: id,
                emailCuenta: emailCuenta,
                resumen: resumen,
                colorFondo: colorFondo,
                rolAcceso: rolAcceso,
                esVisible: esVisible,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarsTableTable,
      CalendarsTableData,
      $$CalendarsTableTableFilterComposer,
      $$CalendarsTableTableOrderingComposer,
      $$CalendarsTableTableAnnotationComposer,
      $$CalendarsTableTableCreateCompanionBuilder,
      $$CalendarsTableTableUpdateCompanionBuilder,
      (
        CalendarsTableData,
        BaseReferences<_$AppDatabase, $CalendarsTableTable, CalendarsTableData>,
      ),
      CalendarsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db, _db.tasksTable);
  $$AccountsTableTableTableManager get accountsTable =>
      $$AccountsTableTableTableManager(_db, _db.accountsTable);
  $$CalendarsTableTableTableManager get calendarsTable =>
      $$CalendarsTableTableTableManager(_db, _db.calendarsTable);
}
