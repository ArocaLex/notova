import 'package:flutter_test/flutter_test.dart';
import 'package:notova/models/task_model.dart';

void main() {
  TaskModel makeTask({
    bool isCompleted = false,
    DateTime? dueDate,
  }) =>
      TaskModel(
        id: '1',
        title: 'Test',
        subtitle: 'Sub',
        priority: 'MED',
        xpReward: 100,
        isCompleted: isCompleted,
        dueDate: dueDate,
      );

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
  });
}
