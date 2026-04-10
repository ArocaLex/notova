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

  setUp(() {
    mockRepo = MockTasksRepository();
    mockUserRepo = MockUserRepository();
    mockAudioRepo = MockAudioRepository();
    viewModel = TasksViewModel(
      repository: mockRepo,
      userRepository: mockUserRepo,
      audioRepository: mockAudioRepo,
    );
  });

  // ── createTask ────────────────────────────────────────────────────────────
  group('createTask', () {
    test('éxito → retorna true, isLoading false, sin errorMessage', () async {
      when(() => mockRepo.addTask(
            title: any(named: 'title'),
            subtitle: any(named: 'subtitle'),
            priority: any(named: 'priority'),
            xpReward: any(named: 'xpReward'),
          )).thenAnswer((_) async {});

      final result = await viewModel.createTask('Tarea', 'Sub', 'HIGH', 250);

      expect(result, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('error → retorna false, establece errorMessage', () async {
      when(() => mockRepo.addTask(
            title: any(named: 'title'),
            subtitle: any(named: 'subtitle'),
            priority: any(named: 'priority'),
            xpReward: any(named: 'xpReward'),
          )).thenThrow(Exception('Firestore error'));

      final result = await viewModel.createTask('Tarea', 'Sub', 'HIGH', 250);

      expect(result, isFalse);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });
  });

  // ── updateTask (G-2) ──────────────────────────────────────────────────────
  group('updateTask', () {
    test('éxito → retorna true, isLoading false', () async {
      when(() => mockRepo.updateTask(
            taskId: any(named: 'taskId'),
            title: any(named: 'title'),
            subtitle: any(named: 'subtitle'),
            priority: any(named: 'priority'),
            xpReward: any(named: 'xpReward'),
          )).thenAnswer((_) async {});

      final result = await viewModel.updateTask('id1', 'Nuevo título', 'Sub', 'MED', 100);

      expect(result, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('error → retorna false, errorMessage contiene "actualizar"', () async {
      when(() => mockRepo.updateTask(
            taskId: any(named: 'taskId'),
            title: any(named: 'title'),
            subtitle: any(named: 'subtitle'),
            priority: any(named: 'priority'),
            xpReward: any(named: 'xpReward'),
          )).thenThrow(Exception('Update failed'));

      final result = await viewModel.updateTask('id1', 'Nuevo', 'Sub', 'MED', 100);

      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('actualizar'));
    });
  });

  // ── toggleTaskCompletion (G-3 level-up) ──────────────────────────────────
  group('toggleTaskCompletion', () {
    setUp(() {
      when(() => mockUserRepo.checkAndUpdateStreak()).thenAnswer((_) async {});
      when(() => mockAudioRepo.playTaskComplete()).thenAnswer((_) async {});
      when(() => mockAudioRepo.playLevelUp()).thenAnswer((_) async {});
    });

    test('sin level-up → retorna false, playLevelUp NO se llama', () async {
      when(() => mockRepo.completeTask(any(), any())).thenAnswer((_) async => false);

      final didLevelUp = await viewModel.toggleTaskCompletion('id1', 100);

      expect(didLevelUp, isFalse);
      verifyNever(() => mockAudioRepo.playLevelUp());
    });

    test('con level-up → retorna true, playLevelUp se llama una vez', () async {
      when(() => mockRepo.completeTask(any(), any())).thenAnswer((_) async => true);

      final didLevelUp = await viewModel.toggleTaskCompletion('id1', 150);

      expect(didLevelUp, isTrue);
      verify(() => mockAudioRepo.playLevelUp()).called(1);
    });

    test('siempre llama playTaskComplete al completar', () async {
      when(() => mockRepo.completeTask(any(), any())).thenAnswer((_) async => false);

      await viewModel.toggleTaskCompletion('id1', 100);

      verify(() => mockAudioRepo.playTaskComplete()).called(1);
    });

    test('error → retorna false, establece errorMessage', () async {
      when(() => mockRepo.completeTask(any(), any())).thenThrow(Exception('Error'));

      final didLevelUp = await viewModel.toggleTaskCompletion('id1', 100);

      expect(didLevelUp, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });
  });
}
