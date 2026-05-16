// Tests the filter/computation logic used by TasksViewModel's getters.
//
// TasksViewModel cannot be directly instantiated in unit tests because its
// constructor subscribes to FirebaseAuth.authStateChanges(), which requires
// a full Firebase environment. The getter logic is tested here using
// standalone mirror functions that replicate the exact same predicates.

import 'package:flutter_test/flutter_test.dart';
import 'package:notova/models/task_model.dart';

// ── Mirror functions matching TasksViewModel getter logic ────────────────────

List<TaskModel> filterNext7Days(List<TaskModel> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final limit = DateTime(now.year, now.month, now.day + 7, 23, 59, 59);
  return tasks
      .where((t) =>
          t.dueDate != null &&
          !t.dueDate!.isBefore(today) &&
          !t.dueDate!.isAfter(limit))
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
}

List<TaskModel> filterCompletedToday(List<TaskModel> tasks) {
  final now = DateTime.now();
  return tasks
      .where((t) =>
          t.completedAt != null &&
          t.completedAt!.year == now.year &&
          t.completedAt!.month == now.month &&
          t.completedAt!.day == now.day)
      .toList();
}

double calcDailyProgress(int completedCount, List<TaskModel> pending) {
  final total = completedCount + pending.length;
  return total > 0 ? completedCount / total : 0.0;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

TaskModel makeTask({
  String id = '1',
  DateTime? dueDate,
  bool isCompleted = false,
  DateTime? completedAt,
}) =>
    TaskModel(
      id: id,
      title: 'Task $id',
      subtitle: '',
      priority: 'MED',
      xpReward: 100,
      isCompleted: isCompleted,
      dueDate: dueDate,
      completedAt: completedAt,
    );

void main() {
  // ── pendingNext7Days filter ──────────────────────────────────────────────
  group('pendingNext7Days filter', () {
    test('tarea sin fecha → excluida', () {
      final result = filterNext7Days([makeTask()]);
      expect(result, isEmpty);
    });

    test('tarea con vencimiento hoy → incluida', () {
      final today = DateTime.now();
      final result = filterNext7Days([makeTask(dueDate: today)]);
      expect(result, hasLength(1));
    });

    test('tarea con vencimiento mañana → incluida', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final result = filterNext7Days([makeTask(dueDate: tomorrow)]);
      expect(result, hasLength(1));
    });

    test('tarea con vencimiento en 7 días → incluida', () {
      final in7Days = DateTime.now().add(const Duration(days: 7));
      final result = filterNext7Days([makeTask(dueDate: in7Days)]);
      expect(result, hasLength(1));
    });

    test('tarea con vencimiento en 8 días → excluida', () {
      final in8Days = DateTime.now().add(const Duration(days: 8));
      final result = filterNext7Days([makeTask(dueDate: in8Days)]);
      expect(result, isEmpty);
    });

    test('tarea con vencimiento ayer → excluida', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = filterNext7Days([makeTask(dueDate: yesterday)]);
      expect(result, isEmpty);
    });

    test('resultados ordenados por fecha ascendente', () {
      final day5 = DateTime.now().add(const Duration(days: 5));
      final day1 = DateTime.now().add(const Duration(days: 1));
      final day3 = DateTime.now().add(const Duration(days: 3));
      final tasks = [
        makeTask(id: 'c', dueDate: day5),
        makeTask(id: 'a', dueDate: day1),
        makeTask(id: 'b', dueDate: day3),
      ];
      final result = filterNext7Days(tasks);
      expect(result.map((t) => t.id).toList(), ['a', 'b', 'c']);
    });

    test('lista vacía → devuelve vacía', () {
      expect(filterNext7Days([]), isEmpty);
    });

    test('mezcla válidas e inválidas → solo las válidas', () {
      final in2Days = DateTime.now().add(const Duration(days: 2));
      final in9Days = DateTime.now().add(const Duration(days: 9));
      final tasks = [
        makeTask(id: '1', dueDate: in2Days),
        makeTask(id: '2'),
        makeTask(id: '3', dueDate: in9Days),
      ];
      final result = filterNext7Days(tasks);
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });
  });

  // ── completedToday filter ────────────────────────────────────────────────
  group('completedToday filter', () {
    test('tarea completada hoy → incluida', () {
      final now = DateTime.now();
      final result = filterCompletedToday([makeTask(completedAt: now)]);
      expect(result, hasLength(1));
    });

    test('tarea completada ayer → excluida', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = filterCompletedToday([makeTask(completedAt: yesterday)]);
      expect(result, isEmpty);
    });

    test('tarea sin completedAt → excluida', () {
      final result = filterCompletedToday([makeTask()]);
      expect(result, isEmpty);
    });

    test('lista vacía → devuelve vacía', () {
      expect(filterCompletedToday([]), isEmpty);
    });

    test('mezcla hoy y ayer → solo las de hoy', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tasks = [
        makeTask(id: '1', completedAt: now),
        makeTask(id: '2', completedAt: yesterday),
        makeTask(id: '3', completedAt: now),
        makeTask(id: '4'),
      ];
      final result = filterCompletedToday(tasks);
      expect(result, hasLength(2));
      expect(result.map((t) => t.id), containsAll(['1', '3']));
    });

    test('tarea completada a medianoche hoy → incluida', () {
      final midnight = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        0,
        0,
        0,
      );
      final result = filterCompletedToday([makeTask(completedAt: midnight)]);
      expect(result, hasLength(1));
    });
  });

  // ── dailyProgress computation ────────────────────────────────────────────
  group('dailyProgress computation', () {
    test('sin tareas ni completadas → 0.0', () {
      expect(calcDailyProgress(0, []), 0.0);
    });

    test('todas completadas, ninguna pendiente → 1.0', () {
      expect(calcDailyProgress(5, []), 1.0);
    });

    test('ninguna completada, 4 pendientes → 0.0', () {
      final pending = List.generate(4, (i) => makeTask(id: '$i'));
      expect(calcDailyProgress(0, pending), 0.0);
    });

    test('2 completadas de 4 total → 0.5', () {
      final pending = [makeTask(id: '1'), makeTask(id: '2')];
      expect(calcDailyProgress(2, pending), 0.5);
    });

    test('1 completada de 4 total → 0.25', () {
      final pending = List.generate(3, (i) => makeTask(id: '$i'));
      expect(calcDailyProgress(1, pending), closeTo(0.25, 0.001));
    });

    test('3 completadas de 4 total → 0.75', () {
      final pending = [makeTask()];
      expect(calcDailyProgress(3, pending), 0.75);
    });

    test('progreso siempre está entre 0.0 y 1.0', () {
      final progress = calcDailyProgress(10, []);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });
  });
}
