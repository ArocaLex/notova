import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notova/repositories/auth_repository.dart';
import 'package:notova/repositories/local_task_repository.dart';
import 'package:notova/repositories/user_repository.dart';
import 'package:notova/viewmodel/auth_viewmodel.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockLocalTaskRepository extends Mock implements LocalTaskRepository {}

void main() {
  late AuthViewModel viewModel;
  late MockAuthRepository mockAuthRepo;
  late MockUserRepository mockUserRepo;
  late MockLocalTaskRepository mockLocalRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockUserRepo = MockUserRepository();
    mockLocalRepo = MockLocalTaskRepository();
    viewModel = AuthViewModel(
      repository: mockAuthRepo,
      userRepository: mockUserRepo,
      localTaskRepository: mockLocalRepo,
    );
  });

  // ── signOut (G-4) ─────────────────────────────────────────────────────────
  group('signOut', () {
    test('limpia caché local ANTES de cerrar sesión (orden correcto)', () async {
      final calls = <String>[];
      when(() => mockLocalRepo.clearLocalCache())
          .thenAnswer((_) async => calls.add('clearCache'));
      when(() => mockAuthRepo.signOut())
          .thenAnswer((_) async => calls.add('signOut'));

      await viewModel.signOut();

      expect(calls, orderedEquals(['clearCache', 'signOut']));
    });

    test('llama clearLocalCache exactamente una vez', () async {
      when(() => mockLocalRepo.clearLocalCache()).thenAnswer((_) async {});
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});

      await viewModel.signOut();

      verify(() => mockLocalRepo.clearLocalCache()).called(1);
      verify(() => mockAuthRepo.signOut()).called(1);
    });
  });

  // ── signInWithEmail ───────────────────────────────────────────────────────
  group('signInWithEmail', () {
    test('éxito → retorna true, isLoading false', () async {
      when(() => mockAuthRepo.signInWithEmail(any(), any()))
          .thenAnswer((_) async => null);

      final result = await viewModel.signInWithEmail('test@test.com', 'pass123');

      expect(result, isTrue);
      expect(viewModel.isLoading, isFalse);
    });

    test('AuthException → retorna false, errorMessage contiene el mensaje', () async {
      when(() => mockAuthRepo.signInWithEmail(any(), any()))
          .thenThrow(AuthException('La contraseña o el correo son incorrectos.'));

      final result = await viewModel.signInWithEmail('test@test.com', 'wrong');

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'La contraseña o el correo son incorrectos.');
    });

    test('excepción genérica → retorna false, errorMessage genérico', () async {
      when(() => mockAuthRepo.signInWithEmail(any(), any()))
          .thenThrow(Exception('Network error'));

      final result = await viewModel.signInWithEmail('test@test.com', 'pass');

      expect(result, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });
  });

  // ── sendPasswordReset ─────────────────────────────────────────────────────
  group('sendPasswordReset', () {
    test('éxito → retorna true', () async {
      when(() => mockAuthRepo.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      final result = await viewModel.sendPasswordReset('test@test.com');

      expect(result, isTrue);
    });

    test('AuthException → retorna false con mensaje de error', () async {
      when(() => mockAuthRepo.sendPasswordResetEmail(any()))
          .thenThrow(AuthException('No existe una cuenta con este correo electrónico.'));

      final result = await viewModel.sendPasswordReset('noexiste@test.com');

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'No existe una cuenta con este correo electrónico.');
    });
  });
}
