import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notova/repositories/audio_repository.dart';
import 'package:notova/repositories/task_repository.dart';
import 'package:notova/repositories/user_repository.dart';
import 'package:notova/viewmodel/task_viewmodel.dart';

class MockTasksRepository extends Mock implements TasksRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  late TasksViewModel viewModel;
  late MockTasksRepository mockRepo;
  late MockUserRepository mockUserRepo;
  late MockAudioRepository mockAudioRepo;

  // Stubs comunes para los métodos del repo que la VM puede invocar en
  // background. No bloquean el test aunque no se asserten.
  void stubRepoDefaults() {
    when(() => mockRepo.setTask(
          taskId: any(named: 'taskId'),
          title: any(named: 'title'),
          subtitle: any(named: 'subtitle'),
          priority: any(named: 'priority'),
          xpReward: any(named: 'xpReward'),
          isCompleted: any(named: 'isCompleted'),
          dueDate: any(named: 'dueDate'),
          createdAt: any(named: 'createdAt'),
          completedAt: any(named: 'completedAt'),
          color: any(named: 'color'),
        )).thenAnswer((_) async {});
    when(() => mockRepo.updateTask(
          taskId: any(named: 'taskId'),
          title: any(named: 'title'),
          subtitle: any(named: 'subtitle'),
          priority: any(named: 'priority'),
          xpReward: any(named: 'xpReward'),
        )).thenAnswer((_) async {});
  }

  setUp(() {
    mockRepo = MockTasksRepository();
    mockUserRepo = MockUserRepository();
    mockAudioRepo = MockAudioRepository();
    stubRepoDefaults();
    viewModel = TasksViewModel(
      repository: mockRepo,
      userRepository: mockUserRepo,
      audioRepository: mockAudioRepo,
    );
  });

  // ── createTask ────────────────────────────────────────────────────────────
  group('createTask', () {
    test('sin auth (generateTaskId == null) → false + errorMessage', () async {
      when(() => mockRepo.generateTaskId()).thenReturn(null);

      final result = await viewModel.createTask('Tarea', 'Sub', 'HIGH', 250);

      expect(result, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });
  });

  // ── toggleTaskCompletion ─────────────────────────────────────────────────
  group('toggleTaskCompletion', () {
    setUp(() {
      when(() => mockUserRepo.checkAndUpdateStreak()).thenAnswer((_) async {});
      when(() => mockAudioRepo.playTaskComplete()).thenAnswer((_) async {});
      when(() => mockAudioRepo.playLevelUp()).thenAnswer((_) async {});
    });

    test('tarea inexistente → retorna false sin error', () async {
      when(() => mockRepo.completeTask(any(), any()))
          .thenAnswer((_) async => false);

      final didLevelUp = await viewModel.toggleTaskCompletion('id_inexistente', 100);

      expect(didLevelUp, isFalse);
    });
  });
}
