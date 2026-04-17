import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de tarea (Quest) de Notova.
///
/// Firestore: /users/{uid}/tasks/{taskId}
class TaskModel {
  final String id;
  final String title;
  final String subtitle;
  final String priority; // 'HIGH' | 'MED' | 'LOW'
  final int xpReward;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? color; // Hex color string e.g. '#FF5252'

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

  factory TaskModel.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      priority: data['priority'] as String? ?? 'MED',
      xpReward: data['xpReward'] as int? ?? 50,
      isCompleted: data['isCompleted'] as bool? ?? false,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      color: data['color'] as String?,
    );
  }

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

  /// True si la tarea tiene fecha de vencimiento pasada y no está completada.
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
