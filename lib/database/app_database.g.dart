// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalTasksTable extends LocalTasks
    with TableInfo<$LocalTasksTable, LocalTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MED'),
  );
  static const VerificationMeta _xpRewardMeta = const VerificationMeta(
    'xpReward',
  );
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
    'xp_reward',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
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
  static const VerificationMeta _pendingPushMeta = const VerificationMeta(
    'pendingPush',
  );
  @override
  late final GeneratedColumn<bool> pendingPush = GeneratedColumn<bool>(
    'pending_push',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_push" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    subtitle,
    priority,
    xpReward,
    isCompleted,
    dueDate,
    createdAt,
    completedAt,
    color,
    pendingPush,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('xp_reward')) {
      context.handle(
        _xpRewardMeta,
        xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('pending_push')) {
      context.handle(
        _pendingPushMeta,
        pendingPush.isAcceptableOrUnknown(
          data['pending_push']!,
          _pendingPushMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      xpReward: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_reward'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      pendingPush: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_push'],
      )!,
    );
  }

  @override
  $LocalTasksTable createAlias(String alias) {
    return $LocalTasksTable(attachedDatabase, alias);
  }
}

class LocalTask extends DataClass implements Insertable<LocalTask> {
  final String id;
  final String title;
  final String subtitle;
  final String priority;
  final int xpReward;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? color;

  /// Marca de mutación local pendiente de empujar a Firestore. Cuando vale
  /// `true` la fila tiene cambios locales que aún no se han sincronizado.
  /// La sync periódica busca estas filas y las empuja en background.
  final bool pendingPush;
  const LocalTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.xpReward,
    required this.isCompleted,
    this.dueDate,
    this.createdAt,
    this.completedAt,
    this.color,
    required this.pendingPush,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    map['priority'] = Variable<String>(priority);
    map['xp_reward'] = Variable<int>(xpReward);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['pending_push'] = Variable<bool>(pendingPush);
    return map;
  }

  LocalTasksCompanion toCompanion(bool nullToAbsent) {
    return LocalTasksCompanion(
      id: Value(id),
      title: Value(title),
      subtitle: Value(subtitle),
      priority: Value(priority),
      xpReward: Value(xpReward),
      isCompleted: Value(isCompleted),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      pendingPush: Value(pendingPush),
    );
  }

  factory LocalTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTask(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      priority: serializer.fromJson<String>(json['priority']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      color: serializer.fromJson<String?>(json['color']),
      pendingPush: serializer.fromJson<bool>(json['pendingPush']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'priority': serializer.toJson<String>(priority),
      'xpReward': serializer.toJson<int>(xpReward),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'color': serializer.toJson<String?>(color),
      'pendingPush': serializer.toJson<bool>(pendingPush),
    };
  }

  LocalTask copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? priority,
    int? xpReward,
    bool? isCompleted,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> color = const Value.absent(),
    bool? pendingPush,
  }) => LocalTask(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    priority: priority ?? this.priority,
    xpReward: xpReward ?? this.xpReward,
    isCompleted: isCompleted ?? this.isCompleted,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    color: color.present ? color.value : this.color,
    pendingPush: pendingPush ?? this.pendingPush,
  );
  LocalTask copyWithCompanion(LocalTasksCompanion data) {
    return LocalTask(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      priority: data.priority.present ? data.priority.value : this.priority,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      color: data.color.present ? data.color.value : this.color,
      pendingPush: data.pendingPush.present
          ? data.pendingPush.value
          : this.pendingPush,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTask(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('priority: $priority, ')
          ..write('xpReward: $xpReward, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('color: $color, ')
          ..write('pendingPush: $pendingPush')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    subtitle,
    priority,
    xpReward,
    isCompleted,
    dueDate,
    createdAt,
    completedAt,
    color,
    pendingPush,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTask &&
          other.id == this.id &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.priority == this.priority &&
          other.xpReward == this.xpReward &&
          other.isCompleted == this.isCompleted &&
          other.dueDate == this.dueDate &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.color == this.color &&
          other.pendingPush == this.pendingPush);
}

class LocalTasksCompanion extends UpdateCompanion<LocalTask> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<String> priority;
  final Value<int> xpReward;
  final Value<bool> isCompleted;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> completedAt;
  final Value<String?> color;
  final Value<bool> pendingPush;
  final Value<int> rowid;
  const LocalTasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.priority = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.color = const Value.absent(),
    this.pendingPush = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTasksCompanion.insert({
    required String id,
    required String title,
    this.subtitle = const Value.absent(),
    this.priority = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.color = const Value.absent(),
    this.pendingPush = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<LocalTask> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? priority,
    Expression<int>? xpReward,
    Expression<bool>? isCompleted,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<String>? color,
    Expression<bool>? pendingPush,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (priority != null) 'priority': priority,
      if (xpReward != null) 'xp_reward': xpReward,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (dueDate != null) 'due_date': dueDate,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (color != null) 'color': color,
      if (pendingPush != null) 'pending_push': pendingPush,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? subtitle,
    Value<String>? priority,
    Value<int>? xpReward,
    Value<bool>? isCompleted,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? completedAt,
    Value<String?>? color,
    Value<bool>? pendingPush,
    Value<int>? rowid,
  }) {
    return LocalTasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      priority: priority ?? this.priority,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      color: color ?? this.color,
      pendingPush: pendingPush ?? this.pendingPush,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (pendingPush.present) {
      map['pending_push'] = Variable<bool>(pendingPush.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('priority: $priority, ')
          ..write('xpReward: $xpReward, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('color: $color, ')
          ..write('pendingPush: $pendingPush, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCalendarAccountsTable extends LocalCalendarAccounts
    with TableInfo<$LocalCalendarAccountsTable, LocalCalendarAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCalendarAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tokenExpiryMeta = const VerificationMeta(
    'tokenExpiry',
  );
  @override
  late final GeneratedColumn<DateTime> tokenExpiry = GeneratedColumn<DateTime>(
    'token_expiry',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _connectedAtMeta = const VerificationMeta(
    'connectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> connectedAt = GeneratedColumn<DateTime>(
    'connected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    email,
    colorValue,
    colorIndex,
    accessToken,
    tokenExpiry,
    connectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_calendar_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCalendarAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    }
    if (data.containsKey('token_expiry')) {
      context.handle(
        _tokenExpiryMeta,
        tokenExpiry.isAcceptableOrUnknown(
          data['token_expiry']!,
          _tokenExpiryMeta,
        ),
      );
    }
    if (data.containsKey('connected_at')) {
      context.handle(
        _connectedAtMeta,
        connectedAt.isAcceptableOrUnknown(
          data['connected_at']!,
          _connectedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {email};
  @override
  LocalCalendarAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCalendarAccount(
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      tokenExpiry: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}token_expiry'],
      ),
      connectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}connected_at'],
      ),
    );
  }

  @override
  $LocalCalendarAccountsTable createAlias(String alias) {
    return $LocalCalendarAccountsTable(attachedDatabase, alias);
  }
}

class LocalCalendarAccount extends DataClass
    implements Insertable<LocalCalendarAccount> {
  final String email;

  /// ARGB del color asignado a la cuenta para los puntitos del grid.
  final int colorValue;

  /// Índice usado en la paleta — para no repetir color al reconectar.
  final int colorIndex;
  final String accessToken;
  final DateTime? tokenExpiry;
  final DateTime? connectedAt;
  const LocalCalendarAccount({
    required this.email,
    required this.colorValue,
    required this.colorIndex,
    required this.accessToken,
    this.tokenExpiry,
    this.connectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['email'] = Variable<String>(email);
    map['color_value'] = Variable<int>(colorValue);
    map['color_index'] = Variable<int>(colorIndex);
    map['access_token'] = Variable<String>(accessToken);
    if (!nullToAbsent || tokenExpiry != null) {
      map['token_expiry'] = Variable<DateTime>(tokenExpiry);
    }
    if (!nullToAbsent || connectedAt != null) {
      map['connected_at'] = Variable<DateTime>(connectedAt);
    }
    return map;
  }

  LocalCalendarAccountsCompanion toCompanion(bool nullToAbsent) {
    return LocalCalendarAccountsCompanion(
      email: Value(email),
      colorValue: Value(colorValue),
      colorIndex: Value(colorIndex),
      accessToken: Value(accessToken),
      tokenExpiry: tokenExpiry == null && nullToAbsent
          ? const Value.absent()
          : Value(tokenExpiry),
      connectedAt: connectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(connectedAt),
    );
  }

  factory LocalCalendarAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCalendarAccount(
      email: serializer.fromJson<String>(json['email']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      tokenExpiry: serializer.fromJson<DateTime?>(json['tokenExpiry']),
      connectedAt: serializer.fromJson<DateTime?>(json['connectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'email': serializer.toJson<String>(email),
      'colorValue': serializer.toJson<int>(colorValue),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'accessToken': serializer.toJson<String>(accessToken),
      'tokenExpiry': serializer.toJson<DateTime?>(tokenExpiry),
      'connectedAt': serializer.toJson<DateTime?>(connectedAt),
    };
  }

  LocalCalendarAccount copyWith({
    String? email,
    int? colorValue,
    int? colorIndex,
    String? accessToken,
    Value<DateTime?> tokenExpiry = const Value.absent(),
    Value<DateTime?> connectedAt = const Value.absent(),
  }) => LocalCalendarAccount(
    email: email ?? this.email,
    colorValue: colorValue ?? this.colorValue,
    colorIndex: colorIndex ?? this.colorIndex,
    accessToken: accessToken ?? this.accessToken,
    tokenExpiry: tokenExpiry.present ? tokenExpiry.value : this.tokenExpiry,
    connectedAt: connectedAt.present ? connectedAt.value : this.connectedAt,
  );
  LocalCalendarAccount copyWithCompanion(LocalCalendarAccountsCompanion data) {
    return LocalCalendarAccount(
      email: data.email.present ? data.email.value : this.email,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      tokenExpiry: data.tokenExpiry.present
          ? data.tokenExpiry.value
          : this.tokenExpiry,
      connectedAt: data.connectedAt.present
          ? data.connectedAt.value
          : this.connectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarAccount(')
          ..write('email: $email, ')
          ..write('colorValue: $colorValue, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('accessToken: $accessToken, ')
          ..write('tokenExpiry: $tokenExpiry, ')
          ..write('connectedAt: $connectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    email,
    colorValue,
    colorIndex,
    accessToken,
    tokenExpiry,
    connectedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCalendarAccount &&
          other.email == this.email &&
          other.colorValue == this.colorValue &&
          other.colorIndex == this.colorIndex &&
          other.accessToken == this.accessToken &&
          other.tokenExpiry == this.tokenExpiry &&
          other.connectedAt == this.connectedAt);
}

class LocalCalendarAccountsCompanion
    extends UpdateCompanion<LocalCalendarAccount> {
  final Value<String> email;
  final Value<int> colorValue;
  final Value<int> colorIndex;
  final Value<String> accessToken;
  final Value<DateTime?> tokenExpiry;
  final Value<DateTime?> connectedAt;
  final Value<int> rowid;
  const LocalCalendarAccountsCompanion({
    this.email = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.tokenExpiry = const Value.absent(),
    this.connectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCalendarAccountsCompanion.insert({
    required String email,
    required int colorValue,
    this.colorIndex = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.tokenExpiry = const Value.absent(),
    this.connectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : email = Value(email),
       colorValue = Value(colorValue);
  static Insertable<LocalCalendarAccount> custom({
    Expression<String>? email,
    Expression<int>? colorValue,
    Expression<int>? colorIndex,
    Expression<String>? accessToken,
    Expression<DateTime>? tokenExpiry,
    Expression<DateTime>? connectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (email != null) 'email': email,
      if (colorValue != null) 'color_value': colorValue,
      if (colorIndex != null) 'color_index': colorIndex,
      if (accessToken != null) 'access_token': accessToken,
      if (tokenExpiry != null) 'token_expiry': tokenExpiry,
      if (connectedAt != null) 'connected_at': connectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCalendarAccountsCompanion copyWith({
    Value<String>? email,
    Value<int>? colorValue,
    Value<int>? colorIndex,
    Value<String>? accessToken,
    Value<DateTime?>? tokenExpiry,
    Value<DateTime?>? connectedAt,
    Value<int>? rowid,
  }) {
    return LocalCalendarAccountsCompanion(
      email: email ?? this.email,
      colorValue: colorValue ?? this.colorValue,
      colorIndex: colorIndex ?? this.colorIndex,
      accessToken: accessToken ?? this.accessToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      connectedAt: connectedAt ?? this.connectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (tokenExpiry.present) {
      map['token_expiry'] = Variable<DateTime>(tokenExpiry.value);
    }
    if (connectedAt.present) {
      map['connected_at'] = Variable<DateTime>(connectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarAccountsCompanion(')
          ..write('email: $email, ')
          ..write('colorValue: $colorValue, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('accessToken: $accessToken, ')
          ..write('tokenExpiry: $tokenExpiry, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCalendarsTable extends LocalCalendars
    with TableInfo<$LocalCalendarsTable, LocalCalendar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCalendarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountEmailMeta = const VerificationMeta(
    'accountEmail',
  );
  @override
  late final GeneratedColumn<String> accountEmail = GeneratedColumn<String>(
    'account_email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Calendario'),
  );
  static const VerificationMeta _backgroundColorMeta = const VerificationMeta(
    'backgroundColor',
  );
  @override
  late final GeneratedColumn<String> backgroundColor = GeneratedColumn<String>(
    'background_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessRoleMeta = const VerificationMeta(
    'accessRole',
  );
  @override
  late final GeneratedColumn<String> accessRole = GeneratedColumn<String>(
    'access_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('reader'),
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'is_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountEmail,
    summary,
    backgroundColor,
    accessRole,
    isVisible,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_calendars';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCalendar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_email')) {
      context.handle(
        _accountEmailMeta,
        accountEmail.isAcceptableOrUnknown(
          data['account_email']!,
          _accountEmailMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountEmailMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('background_color')) {
      context.handle(
        _backgroundColorMeta,
        backgroundColor.isAcceptableOrUnknown(
          data['background_color']!,
          _backgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('access_role')) {
      context.handle(
        _accessRoleMeta,
        accessRole.isAcceptableOrUnknown(data['access_role']!, _accessRoleMeta),
      );
    }
    if (data.containsKey('is_visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, accountEmail};
  @override
  LocalCalendar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCalendar(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_email'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      backgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_color'],
      ),
      accessRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_role'],
      )!,
      isVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_visible'],
      )!,
    );
  }

  @override
  $LocalCalendarsTable createAlias(String alias) {
    return $LocalCalendarsTable(attachedDatabase, alias);
  }
}

class LocalCalendar extends DataClass implements Insertable<LocalCalendar> {
  final String id;
  final String accountEmail;
  final String summary;
  final String? backgroundColor;
  final String accessRole;
  final bool isVisible;
  const LocalCalendar({
    required this.id,
    required this.accountEmail,
    required this.summary,
    this.backgroundColor,
    required this.accessRole,
    required this.isVisible,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_email'] = Variable<String>(accountEmail);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || backgroundColor != null) {
      map['background_color'] = Variable<String>(backgroundColor);
    }
    map['access_role'] = Variable<String>(accessRole);
    map['is_visible'] = Variable<bool>(isVisible);
    return map;
  }

  LocalCalendarsCompanion toCompanion(bool nullToAbsent) {
    return LocalCalendarsCompanion(
      id: Value(id),
      accountEmail: Value(accountEmail),
      summary: Value(summary),
      backgroundColor: backgroundColor == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundColor),
      accessRole: Value(accessRole),
      isVisible: Value(isVisible),
    );
  }

  factory LocalCalendar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCalendar(
      id: serializer.fromJson<String>(json['id']),
      accountEmail: serializer.fromJson<String>(json['accountEmail']),
      summary: serializer.fromJson<String>(json['summary']),
      backgroundColor: serializer.fromJson<String?>(json['backgroundColor']),
      accessRole: serializer.fromJson<String>(json['accessRole']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountEmail': serializer.toJson<String>(accountEmail),
      'summary': serializer.toJson<String>(summary),
      'backgroundColor': serializer.toJson<String?>(backgroundColor),
      'accessRole': serializer.toJson<String>(accessRole),
      'isVisible': serializer.toJson<bool>(isVisible),
    };
  }

  LocalCalendar copyWith({
    String? id,
    String? accountEmail,
    String? summary,
    Value<String?> backgroundColor = const Value.absent(),
    String? accessRole,
    bool? isVisible,
  }) => LocalCalendar(
    id: id ?? this.id,
    accountEmail: accountEmail ?? this.accountEmail,
    summary: summary ?? this.summary,
    backgroundColor: backgroundColor.present
        ? backgroundColor.value
        : this.backgroundColor,
    accessRole: accessRole ?? this.accessRole,
    isVisible: isVisible ?? this.isVisible,
  );
  LocalCalendar copyWithCompanion(LocalCalendarsCompanion data) {
    return LocalCalendar(
      id: data.id.present ? data.id.value : this.id,
      accountEmail: data.accountEmail.present
          ? data.accountEmail.value
          : this.accountEmail,
      summary: data.summary.present ? data.summary.value : this.summary,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      accessRole: data.accessRole.present
          ? data.accessRole.value
          : this.accessRole,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendar(')
          ..write('id: $id, ')
          ..write('accountEmail: $accountEmail, ')
          ..write('summary: $summary, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('accessRole: $accessRole, ')
          ..write('isVisible: $isVisible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountEmail,
    summary,
    backgroundColor,
    accessRole,
    isVisible,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCalendar &&
          other.id == this.id &&
          other.accountEmail == this.accountEmail &&
          other.summary == this.summary &&
          other.backgroundColor == this.backgroundColor &&
          other.accessRole == this.accessRole &&
          other.isVisible == this.isVisible);
}

class LocalCalendarsCompanion extends UpdateCompanion<LocalCalendar> {
  final Value<String> id;
  final Value<String> accountEmail;
  final Value<String> summary;
  final Value<String?> backgroundColor;
  final Value<String> accessRole;
  final Value<bool> isVisible;
  final Value<int> rowid;
  const LocalCalendarsCompanion({
    this.id = const Value.absent(),
    this.accountEmail = const Value.absent(),
    this.summary = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.accessRole = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCalendarsCompanion.insert({
    required String id,
    required String accountEmail,
    this.summary = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.accessRole = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountEmail = Value(accountEmail);
  static Insertable<LocalCalendar> custom({
    Expression<String>? id,
    Expression<String>? accountEmail,
    Expression<String>? summary,
    Expression<String>? backgroundColor,
    Expression<String>? accessRole,
    Expression<bool>? isVisible,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountEmail != null) 'account_email': accountEmail,
      if (summary != null) 'summary': summary,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (accessRole != null) 'access_role': accessRole,
      if (isVisible != null) 'is_visible': isVisible,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCalendarsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountEmail,
    Value<String>? summary,
    Value<String?>? backgroundColor,
    Value<String>? accessRole,
    Value<bool>? isVisible,
    Value<int>? rowid,
  }) {
    return LocalCalendarsCompanion(
      id: id ?? this.id,
      accountEmail: accountEmail ?? this.accountEmail,
      summary: summary ?? this.summary,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      accessRole: accessRole ?? this.accessRole,
      isVisible: isVisible ?? this.isVisible,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountEmail.present) {
      map['account_email'] = Variable<String>(accountEmail.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<String>(backgroundColor.value);
    }
    if (accessRole.present) {
      map['access_role'] = Variable<String>(accessRole.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCalendarsCompanion(')
          ..write('id: $id, ')
          ..write('accountEmail: $accountEmail, ')
          ..write('summary: $summary, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('accessRole: $accessRole, ')
          ..write('isVisible: $isVisible, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTasksTable localTasks = $LocalTasksTable(this);
  late final $LocalCalendarAccountsTable localCalendarAccounts =
      $LocalCalendarAccountsTable(this);
  late final $LocalCalendarsTable localCalendars = $LocalCalendarsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTasks,
    localCalendarAccounts,
    localCalendars,
  ];
}

typedef $$LocalTasksTableCreateCompanionBuilder =
    LocalTasksCompanion Function({
      required String id,
      required String title,
      Value<String> subtitle,
      Value<String> priority,
      Value<int> xpReward,
      Value<bool> isCompleted,
      Value<DateTime?> dueDate,
      Value<DateTime?> createdAt,
      Value<DateTime?> completedAt,
      Value<String?> color,
      Value<bool> pendingPush,
      Value<int> rowid,
    });
typedef $$LocalTasksTableUpdateCompanionBuilder =
    LocalTasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> subtitle,
      Value<String> priority,
      Value<int> xpReward,
      Value<bool> isCompleted,
      Value<DateTime?> dueDate,
      Value<DateTime?> createdAt,
      Value<DateTime?> completedAt,
      Value<String?> color,
      Value<bool> pendingPush,
      Value<int> rowid,
    });

class $$LocalTasksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingPush => $composableBuilder(
    column: $table.pendingPush,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingPush => $composableBuilder(
    column: $table.pendingPush,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get pendingPush => $composableBuilder(
    column: $table.pendingPush,
    builder: (column) => column,
  );
}

class $$LocalTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTasksTable,
          LocalTask,
          $$LocalTasksTableFilterComposer,
          $$LocalTasksTableOrderingComposer,
          $$LocalTasksTableAnnotationComposer,
          $$LocalTasksTableCreateCompanionBuilder,
          $$LocalTasksTableUpdateCompanionBuilder,
          (
            LocalTask,
            BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>,
          ),
          LocalTask,
          PrefetchHooks Function()
        > {
  $$LocalTasksTableTableManager(_$AppDatabase db, $LocalTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> xpReward = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> pendingPush = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTasksCompanion(
                id: id,
                title: title,
                subtitle: subtitle,
                priority: priority,
                xpReward: xpReward,
                isCompleted: isCompleted,
                dueDate: dueDate,
                createdAt: createdAt,
                completedAt: completedAt,
                color: color,
                pendingPush: pendingPush,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> subtitle = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> xpReward = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> pendingPush = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTasksCompanion.insert(
                id: id,
                title: title,
                subtitle: subtitle,
                priority: priority,
                xpReward: xpReward,
                isCompleted: isCompleted,
                dueDate: dueDate,
                createdAt: createdAt,
                completedAt: completedAt,
                color: color,
                pendingPush: pendingPush,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTasksTable,
      LocalTask,
      $$LocalTasksTableFilterComposer,
      $$LocalTasksTableOrderingComposer,
      $$LocalTasksTableAnnotationComposer,
      $$LocalTasksTableCreateCompanionBuilder,
      $$LocalTasksTableUpdateCompanionBuilder,
      (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
      LocalTask,
      PrefetchHooks Function()
    >;
typedef $$LocalCalendarAccountsTableCreateCompanionBuilder =
    LocalCalendarAccountsCompanion Function({
      required String email,
      required int colorValue,
      Value<int> colorIndex,
      Value<String> accessToken,
      Value<DateTime?> tokenExpiry,
      Value<DateTime?> connectedAt,
      Value<int> rowid,
    });
typedef $$LocalCalendarAccountsTableUpdateCompanionBuilder =
    LocalCalendarAccountsCompanion Function({
      Value<String> email,
      Value<int> colorValue,
      Value<int> colorIndex,
      Value<String> accessToken,
      Value<DateTime?> tokenExpiry,
      Value<DateTime?> connectedAt,
      Value<int> rowid,
    });

class $$LocalCalendarAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCalendarAccountsTable> {
  $$LocalCalendarAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tokenExpiry => $composableBuilder(
    column: $table.tokenExpiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCalendarAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCalendarAccountsTable> {
  $$LocalCalendarAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tokenExpiry => $composableBuilder(
    column: $table.tokenExpiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCalendarAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCalendarAccountsTable> {
  $$LocalCalendarAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get tokenExpiry => $composableBuilder(
    column: $table.tokenExpiry,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => column,
  );
}

class $$LocalCalendarAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCalendarAccountsTable,
          LocalCalendarAccount,
          $$LocalCalendarAccountsTableFilterComposer,
          $$LocalCalendarAccountsTableOrderingComposer,
          $$LocalCalendarAccountsTableAnnotationComposer,
          $$LocalCalendarAccountsTableCreateCompanionBuilder,
          $$LocalCalendarAccountsTableUpdateCompanionBuilder,
          (
            LocalCalendarAccount,
            BaseReferences<
              _$AppDatabase,
              $LocalCalendarAccountsTable,
              LocalCalendarAccount
            >,
          ),
          LocalCalendarAccount,
          PrefetchHooks Function()
        > {
  $$LocalCalendarAccountsTableTableManager(
    _$AppDatabase db,
    $LocalCalendarAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCalendarAccountsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalCalendarAccountsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalCalendarAccountsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> email = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<DateTime?> tokenExpiry = const Value.absent(),
                Value<DateTime?> connectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarAccountsCompanion(
                email: email,
                colorValue: colorValue,
                colorIndex: colorIndex,
                accessToken: accessToken,
                tokenExpiry: tokenExpiry,
                connectedAt: connectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String email,
                required int colorValue,
                Value<int> colorIndex = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<DateTime?> tokenExpiry = const Value.absent(),
                Value<DateTime?> connectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarAccountsCompanion.insert(
                email: email,
                colorValue: colorValue,
                colorIndex: colorIndex,
                accessToken: accessToken,
                tokenExpiry: tokenExpiry,
                connectedAt: connectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCalendarAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCalendarAccountsTable,
      LocalCalendarAccount,
      $$LocalCalendarAccountsTableFilterComposer,
      $$LocalCalendarAccountsTableOrderingComposer,
      $$LocalCalendarAccountsTableAnnotationComposer,
      $$LocalCalendarAccountsTableCreateCompanionBuilder,
      $$LocalCalendarAccountsTableUpdateCompanionBuilder,
      (
        LocalCalendarAccount,
        BaseReferences<
          _$AppDatabase,
          $LocalCalendarAccountsTable,
          LocalCalendarAccount
        >,
      ),
      LocalCalendarAccount,
      PrefetchHooks Function()
    >;
typedef $$LocalCalendarsTableCreateCompanionBuilder =
    LocalCalendarsCompanion Function({
      required String id,
      required String accountEmail,
      Value<String> summary,
      Value<String?> backgroundColor,
      Value<String> accessRole,
      Value<bool> isVisible,
      Value<int> rowid,
    });
typedef $$LocalCalendarsTableUpdateCompanionBuilder =
    LocalCalendarsCompanion Function({
      Value<String> id,
      Value<String> accountEmail,
      Value<String> summary,
      Value<String?> backgroundColor,
      Value<String> accessRole,
      Value<bool> isVisible,
      Value<int> rowid,
    });

class $$LocalCalendarsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCalendarsTable> {
  $$LocalCalendarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountEmail => $composableBuilder(
    column: $table.accountEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCalendarsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCalendarsTable> {
  $$LocalCalendarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountEmail => $composableBuilder(
    column: $table.accountEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCalendarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCalendarsTable> {
  $$LocalCalendarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountEmail => $composableBuilder(
    column: $table.accountEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessRole => $composableBuilder(
    column: $table.accessRole,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);
}

class $$LocalCalendarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCalendarsTable,
          LocalCalendar,
          $$LocalCalendarsTableFilterComposer,
          $$LocalCalendarsTableOrderingComposer,
          $$LocalCalendarsTableAnnotationComposer,
          $$LocalCalendarsTableCreateCompanionBuilder,
          $$LocalCalendarsTableUpdateCompanionBuilder,
          (
            LocalCalendar,
            BaseReferences<_$AppDatabase, $LocalCalendarsTable, LocalCalendar>,
          ),
          LocalCalendar,
          PrefetchHooks Function()
        > {
  $$LocalCalendarsTableTableManager(
    _$AppDatabase db,
    $LocalCalendarsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCalendarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCalendarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCalendarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountEmail = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> backgroundColor = const Value.absent(),
                Value<String> accessRole = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarsCompanion(
                id: id,
                accountEmail: accountEmail,
                summary: summary,
                backgroundColor: backgroundColor,
                accessRole: accessRole,
                isVisible: isVisible,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountEmail,
                Value<String> summary = const Value.absent(),
                Value<String?> backgroundColor = const Value.absent(),
                Value<String> accessRole = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCalendarsCompanion.insert(
                id: id,
                accountEmail: accountEmail,
                summary: summary,
                backgroundColor: backgroundColor,
                accessRole: accessRole,
                isVisible: isVisible,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCalendarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCalendarsTable,
      LocalCalendar,
      $$LocalCalendarsTableFilterComposer,
      $$LocalCalendarsTableOrderingComposer,
      $$LocalCalendarsTableAnnotationComposer,
      $$LocalCalendarsTableCreateCompanionBuilder,
      $$LocalCalendarsTableUpdateCompanionBuilder,
      (
        LocalCalendar,
        BaseReferences<_$AppDatabase, $LocalCalendarsTable, LocalCalendar>,
      ),
      LocalCalendar,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTasksTableTableManager get localTasks =>
      $$LocalTasksTableTableManager(_db, _db.localTasks);
  $$LocalCalendarAccountsTableTableManager get localCalendarAccounts =>
      $$LocalCalendarAccountsTableTableManager(_db, _db.localCalendarAccounts);
  $$LocalCalendarsTableTableManager get localCalendars =>
      $$LocalCalendarsTableTableManager(_db, _db.localCalendars);
}
