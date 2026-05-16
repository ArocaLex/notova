import 'package:flutter_test/flutter_test.dart';
import 'package:notova/models/task_model.dart';

TaskModel makeTask({
  String id = '1',
  String title = 'Test',
  String subtitle = 'Sub',
  String priority = 'MED',
  int xpReward = 100,
  bool isCompleted = false,
  DateTime? dueDate,
  DateTime? createdAt,
  DateTime? completedAt,
  String? color,
}) =>
    TaskModel(
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
    );

void main() {
  // ── isOverdue ─────────────────────────────────────────────────────────────
  group('TaskModel.isOverdue', () {
    test('fecha pasada y no completada → true', () {
      final task = makeTask(dueDate: DateTime.now().subtract(const Duration(hours: 1)));
      expect(task.isOverdue, isTrue);
    });
    test('fecha futura y no completada → false', () {
      final task = makeTask(dueDate: DateTime.now().add(const Duration(hours: 1)));
      expect(task.isOverdue, isFalse);
    });
    test('fecha pasada pero completada → false', () {
      final task = makeTask(
        isCompleted: true,
        dueDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(task.isOverdue, isFalse);
    });
    test('sin fecha → false', () {
      expect(makeTask().isOverdue, isFalse);
    });
    test('vence exactamente ahora (milisegundo antes) → true', () {
      final task = makeTask(dueDate: DateTime.now().subtract(const Duration(milliseconds: 1)));
      expect(task.isOverdue, isTrue);
    });
  });

  // ── formattedDueDate ──────────────────────────────────────────────────────
  group('TaskModel.formattedDueDate', () {
    test('sin fecha → cadena vacía', () {
      expect(makeTask().formattedDueDate, isEmpty);
    });
    test('fecha con hora → formato d/M  HH:MM', () {
      final task = makeTask(dueDate: DateTime(2026, 4, 10, 14, 5));
      expect(task.formattedDueDate, '10/4  14:05');
    });
    test('hora 00:00 → se muestra 00:00', () {
      final task = makeTask(dueDate: DateTime(2026, 4, 10, 0, 0));
      expect(task.formattedDueDate, '10/4  00:00');
    });
    test('minutos con un dígito se rellenan con cero', () {
      final task = makeTask(dueDate: DateTime(2026, 12, 1, 9, 3));
      expect(task.formattedDueDate, '1/12  09:03');
    });
    test('hora 23:59 → se muestra correctamente', () {
      final task = makeTask(dueDate: DateTime(2026, 6, 15, 23, 59));
      expect(task.formattedDueDate, '15/6  23:59');
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────
  group('TaskModel.copyWith', () {
    test('sin cambios → valores originales se preservan', () {
      final original = makeTask(
        id: 'orig',
        title: 'Original',
        priority: 'HIGH',
        xpReward: 200,
        color: '#FF5252',
      );
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.priority, original.priority);
      expect(copy.xpReward, original.xpReward);
      expect(copy.color, original.color);
    });

    test('copyWith isCompleted cambia solo ese campo', () {
      final task = makeTask(isCompleted: false);
      final completed = task.copyWith(isCompleted: true);

      expect(completed.isCompleted, isTrue);
      expect(completed.id, task.id);
      expect(completed.title, task.title);
    });

    test('copyWith completedAt actualiza la fecha', () {
      final now = DateTime(2026, 5, 11, 14, 0);
      final task = makeTask();
      final done = task.copyWith(isCompleted: true, completedAt: now);

      expect(done.completedAt, now);
      expect(done.isCompleted, isTrue);
    });

    test('copyWith title y subtitle cambian solo esos campos', () {
      final task = makeTask(title: 'Old', subtitle: 'Old sub');
      final updated = task.copyWith(title: 'New', subtitle: 'New sub');

      expect(updated.title, 'New');
      expect(updated.subtitle, 'New sub');
      expect(updated.id, task.id);
    });

    test('copyWith dueDate actualiza la fecha de vencimiento', () {
      final newDate = DateTime(2026, 12, 31);
      final task = makeTask();
      final updated = task.copyWith(dueDate: newDate);

      expect(updated.dueDate, newDate);
    });

    test('copyWith color actualiza el color', () {
      final task = makeTask(color: '#FF0000');
      final updated = task.copyWith(color: '#00FF00');

      expect(updated.color, '#00FF00');
    });

    test('id no cambia con copyWith (es inmutable)', () {
      final task = makeTask(id: 'fixed-id');
      final copy = task.copyWith(title: 'Changed');

      expect(copy.id, 'fixed-id');
    });

    test('createdAt se preserva en copyWith', () {
      final created = DateTime(2026, 1, 1);
      final task = makeTask(createdAt: created);
      final copy = task.copyWith(title: 'Changed');

      expect(copy.createdAt, created);
    });
  });
}
