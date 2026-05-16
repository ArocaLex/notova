import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una tarea (Quest) dentro de Notova.
///
/// Cada tarea posee una prioridad (`'HIGH'`, `'MED'` o `'LOW'`), una
/// recompensa en XP y, opcionalmente, un color hexadecimal (por ejemplo,
/// `'#FF5252'`) para personalizar su apariencia en la interfaz.
///
/// Firestore: `/users/{uid}/tasks/{taskId}`.
class TaskModel {
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

  const TaskModel({
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
  });

  /// Crea una instancia de [TaskModel] a partir de un [QueryDocumentSnapshot]
  /// de Firestore, aplicando valores por defecto cuando los campos son nulos.
  factory TaskModel.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      priority: data['priority'] as String? ?? 'MED',
      xpReward: data['xpReward'] as int? ?? 100,
      isCompleted: data['isCompleted'] as bool? ?? false,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      color: data['color'] as String?,
    );
  }

  /// Retorna una copia de esta [TaskModel] con los campos indicados
  /// reemplazados por los nuevos valores proporcionados.
  TaskModel copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    String? title,
    String? subtitle,
    String? priority,
    int? xpReward,
    DateTime? dueDate,
    String? color,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      priority: priority ?? this.priority,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      color: color ?? this.color,
    );
  }

  /// Indica si la tarea tiene una fecha de vencimiento pasada y aun no ha
  /// sido completada.
  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  /// Fecha de vencimiento formateada para mostrar en la UI.
  String get formattedDueDate {
    if (dueDate == null) return '';
    final d = dueDate!;
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}  $hour:$min';
  }
}
