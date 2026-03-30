import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool isLoading = false;
  String? errorMessage;

  void _setLoading(bool value) {
    isLoading = value;
    if (value) errorMessage = null; 
    notifyListeners();
  }

  // =========================================================
  // 1. AUTENTICACIÓN CON GOOGLE
  // =========================================================
  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      final User? user = await _repository.signInWithGoogle();

      if (user != null) {
        await _createInitialUserProfile(user);
        _setLoading(false);
        return true; // Éxito
      } else {
        _setLoading(false);
        return false; // Cancelado por el usuario
      }
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado al conectar con Google.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 2. INICIAR SESIÓN CON EMAIL Y CONTRASEÑA
  // =========================================================
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);

    try {
      await _repository.signInWithEmail(email, password);
      _setLoading(false);
      return true; // Éxito
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado al iniciar sesión.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 3. REGISTRARSE CON EMAIL Y CONTRASEÑA
  // =========================================================
  Future<bool> registerWithEmail(String email, String password) async {
    _setLoading(true);

    try {
      final User? user = await _repository.registerWithEmail(email, password);

      if (user != null) {
        await _createInitialUserProfile(user);
      }
      _setLoading(false);
      return true; // Éxito
    } on AuthException catch (e) {
      errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado al registrarte.';
      _setLoading(false);
      return false;
    }
  }

  // =========================================================
  // 4. CERRAR SESIÓN
  // =========================================================
  Future<void> signOut() async {
    await _repository.signOut();
  }

  // =========================================================
  // 5. CREACIÓN DEL PERFIL EN FIRESTORE
  // =========================================================
  Future<void> _createInitialUserProfile(User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0],
        'level': 1,
        'currentXp': 0,
        'totalXp': 1000,
        'dayStreak': 0,
        'rank': 'Beginner',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
