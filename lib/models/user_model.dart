import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa al usuario autenticado en Notova.
///
/// Implementa el sistema de niveles definido en el PRD v1.0, donde el nivel
/// se calcula a partir del XP total acumulado:
///
/// | Nivel | Rango        | XP requerida    |
/// |-------|------------- |-----------------|
/// | 1     | Novato       | 0 -- 150        |
/// | 2     | Aspirante    | 151 -- 500      |
/// | 3     | Tactico      | 501 -- 1 200    |
/// | 4     | Ninja        | 1 201 -- 2 500  |
/// | 5     | Maestro      | 2 501 -- 4 500  |
/// | 6     | Leyenda      | 4 501 -- 7 500  |
/// | 7     | SuperNotova  | 7 501+          |
///
/// Firestore: `/users/{uid}`.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final int level;
  final int totalXpEver;
  final int dayStreak;
  final String rank;
  final int badgesCount;
  final List<String> badges;
  final DateTime? createdAt;
  final DateTime? lastActivityDate;
  final String? avatarUrl;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.level = 1,
    this.totalXpEver = 0,
    this.dayStreak = 0,
    this.rank = 'Novato',
    this.badgesCount = 0,
    this.badges = const [],
    this.createdAt,
    this.lastActivityDate,
    this.avatarUrl,
  });

  /// Tabla de umbrales de nivel definida en el PRD.
  ///
  /// Cada entrada es una tupla `(nivel, xpMinimo, xpMaximo)`.
  static const List<(int, int, int)> _thresholds = [
    (1, 0, 150),
    (2, 151, 500),
    (3, 501, 1200),
    (4, 1201, 2500),
    (5, 2501, 4500),
    (6, 4501, 7500),
    (7, 7501, 99999999),
  ];

  /// Nombres de rango ordenados por nivel (indice 0 = nivel 1).
  static const List<String> _rankNames = [
    'Novato',
    'Aspirante',
    'Táctico',
    'Ninja',
    'Maestro',
    'Leyenda',
    'SuperNotova',
  ];

  /// Calcula el nivel (1-7) a partir del XP total acumulado.
  static int levelFromXp(int totalXp) {
    for (var i = _thresholds.length - 1; i >= 0; i--) {
      if (totalXp >= _thresholds[i].$2) return _thresholds[i].$1;
    }
    return 1;
  }

  /// Retorna el nombre de rango según el nivel.
  static String rankForLevel(int level) {
    final idx = (level - 1).clamp(0, _rankNames.length - 1);
    return _rankNames[idx];
  }

  /// Progreso hacia el siguiente nivel, expresado como un valor entre
  /// `0.0` y `1.0`.
  double get xpProgress {
    if (level >= 7) return 1.0;
    final (_, min, max) = _thresholds[level - 1];
    final range = max - min;
    if (range <= 0) return 1.0;
    return ((totalXpEver - min) / range).clamp(0.0, 1.0);
  }

  /// Retorna la cantidad de XP restante para alcanzar el siguiente nivel.
  int get xpRemaining {
    if (level >= 7) return 0;
    final (_, _, max) = _thresholds[level - 1];
    return (max - totalXpEver).clamp(0, max);
  }

  /// Obtiene la XP minima requerida para el nivel actual.
  int get currentLevelMinXp => _thresholds[(level - 1).clamp(0, 6)].$2;

  /// Obtiene la XP maxima del nivel actual.
  int get currentLevelMaxXp => _thresholds[(level - 1).clamp(0, 6)].$3;

  /// Crea una instancia de [UserModel] a partir de un [DocumentSnapshot]
  /// de Firestore, recalculando el nivel con [levelFromXp].
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final totalXpEver = data['totalXpEver'] as int? ?? 0;
    final level = levelFromXp(totalXpEver);
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? 'Usuario',
      level: level,
      totalXpEver: totalXpEver,
      dayStreak: data['dayStreak'] as int? ?? 0,
      rank: data['rank'] as String? ?? rankForLevel(level),
      badgesCount: data['badgesCount'] as int? ?? 0,
      badges: List<String>.from(data['badges'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  /// Serializa este [UserModel] a un mapa JSON, utilizado para la cache
  /// local en SharedPreferences.
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'level': level,
        'totalXpEver': totalXpEver,
        'dayStreak': dayStreak,
        'rank': rank,
        'badgesCount': badgesCount,
        'badges': badges,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'lastActivityDate': lastActivityDate?.millisecondsSinceEpoch,
        'avatarUrl': avatarUrl,
      };

  /// Reconstruye un [UserModel] desde un mapa JSON serializado previamente
  /// con [toJson], recalculando el nivel con [levelFromXp].
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final totalXpEver = json['totalXpEver'] as int? ?? 0;
    final level = levelFromXp(totalXpEver);
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'Usuario',
      level: level,
      totalXpEver: totalXpEver,
      dayStreak: json['dayStreak'] as int? ?? 0,
      rank: json['rank'] as String? ?? rankForLevel(level),
      badgesCount: json['badgesCount'] as int? ?? 0,
      badges: List<String>.from(json['badges'] as List? ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : null,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['lastActivityDate'] as int)
          : null,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  /// Genera el mapa de datos iniciales para crear el documento del usuario en
  /// Firestore. Utiliza `FieldValue.serverTimestamp()` para el campo `createdAt`.
  static Map<String, dynamic> initialData({
    required String email,
    required String? displayName,
  }) {
    return {
      'email': email,
      'name': displayName ?? email.split('@')[0],
      'level': 1,
      'totalXpEver': 0,
      'dayStreak': 0,
      'rank': 'Novato',
      'badgesCount': 0,
      'badges': [],
      'lastActivityDate': null,
      'avatarUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
