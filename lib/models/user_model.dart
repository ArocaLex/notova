import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================================
/// MODELO DE USUARIO — UserModel
/// ============================================================================
///
/// Representa al usuario dentro de Notova. Cada campo corresponde directamente
/// a un campo en el documento Firestore ubicado en:
///
///   Firestore: /users/{uid}
///
/// Campos almacenados:
///   - [email]        → Correo electronico del usuario.
///   - [name]         → Nombre visible en la app.
///   - [level]        → Nivel actual (empieza en 1).
///   - [currentXp]    → XP acumulada en el nivel actual.
///   - [totalXp]      → XP necesaria para subir al siguiente nivel.
///   - [totalXpEver]  → XP total ganada historicamente (nunca se reinicia).
///   - [dayStreak]    → Dias consecutivos de actividad.
///   - [rank]         → Rango textual segun el nivel (Beginner, Intermediate...).
///   - [badgesCount]  → Numero de insignias desbloqueadas.
///   - [createdAt]    → Fecha de creacion del perfil.
///
/// Propiedades calculadas:
///   - [xpProgress]   → Progreso hacia el siguiente nivel (0.0 – 1.0).
///   - [xpRemaining]  → XP que falta para subir de nivel.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final int level;
  final int currentXp;
  final int totalXp;
  final int totalXpEver;
  final int dayStreak;
  final String rank;
  final int badgesCount;
  final DateTime? createdAt;

  /// Constructor principal.
  ///
  /// Solo [uid], [email] y [name] son obligatorios. El resto tiene valores
  /// por defecto que coinciden con los de un usuario recien creado.
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.totalXp = 1000,
    this.totalXpEver = 0,
    this.dayStreak = 0,
    this.rank = 'Beginner',
    this.badgesCount = 0,
    this.createdAt,
  });

  // ── Propiedades calculadas ────────────────────────────────────────────────

  /// Porcentaje de progreso hacia el siguiente nivel (0.0 – 1.0).
  /// Utilizado por las barras de progreso en HomeScreen y ProfileScreen.
  double get xpProgress => totalXp > 0 ? (currentXp / totalXp).clamp(0.0, 1.0) : 0.0;

  /// XP restante para subir de nivel.
  /// Ejemplo: si currentXp = 700 y totalXp = 1000, devuelve 300.
  int get xpRemaining => (totalXp - currentXp).clamp(0, totalXp);

  // ── Factory: Firestore → UserModel ────────────────────────────────────────

  /// Crea un [UserModel] a partir de un [DocumentSnapshot] de Firestore.
  ///
  /// Cada campo se lee con null-safety: si el campo no existe en el documento,
  /// se usa un valor por defecto seguro. Esto evita errores si el esquema
  /// de Firestore cambia o si un documento fue creado parcialmente.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? 'Usuario',
      level: data['level'] as int? ?? 1,
      currentXp: data['currentXp'] as int? ?? 0,
      totalXp: data['totalXp'] as int? ?? 1000,
      totalXpEver: data['totalXpEver'] as int? ?? (data['currentXp'] as int? ?? 0),
      dayStreak: data['dayStreak'] as int? ?? 0,
      rank: data['rank'] as String? ?? 'Beginner',
      badgesCount: data['badgesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // ── Datos iniciales para Firestore ────────────────────────────────────────

  /// Genera el mapa de datos para crear un usuario nuevo en Firestore.
  ///
  /// Se usa en [UserRepository.createIfNotExists] cuando un usuario se
  /// registra por primera vez (email o Google). Si no tiene displayName,
  /// se extrae la parte antes del '@' del email como nombre.
  ///
  /// El campo 'createdAt' usa [FieldValue.serverTimestamp()] para que
  /// la fecha sea asignada por el servidor de Firebase (evita problemas
  /// con relojes locales desincronizados).
  static Map<String, dynamic> initialData({
    required String email,
    required String? displayName,
  }) {
    return {
      'email': email,
      'name': displayName ?? email.split('@')[0],
      'level': 1,
      'currentXp': 0,
      'totalXp': 1000,
      'totalXpEver': 0,
      'dayStreak': 0,
      'rank': 'Beginner',
      'badgesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
