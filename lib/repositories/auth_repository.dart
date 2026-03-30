import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _auth;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized) {
      await _googleSignIn.initialize();
      _isGoogleInitialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // 2. La nueva API usa authenticate() en lugar de signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 3. Obtener el idToken de la autenticación
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final scopes = <String>['email', 'profile'];
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(scopes);

      // 5. Crear credencial para Firebase combinando ambos tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      // 6. Iniciar sesión en Firebase (Firebase guardará la sesión en el dispositivo)
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }

  /// Iniciar sesión con Email y Contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  /// Registrar nuevo usuario
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateAuthError(e.code));
    } catch (e) {
      throw AuthException('Ocurrió un error inesperado al registrarte.');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      if (_isGoogleInitialized) {
        await _googleSignIn.disconnect();
      }
      await _auth.signOut(); // Esto borra la sesión persistente de Firebase
    } catch (e) {
      throw AuthException('Error al cerrar sesión.');
    }
  }

  String _translateAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña o el correo son incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado en Notova.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Revisa tu conexión a internet.';
      default:
        return 'Error de autenticación ($errorCode). Inténtalo de nuevo.';
    }
  }
}
