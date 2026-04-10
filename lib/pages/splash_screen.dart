import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/local_task_repository.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String? _userName;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _checkAuthState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Usuario';
      });
      // Sincroniza tareas de Firestore → SQLite (caché offline)
      LocalTaskRepository().syncFromFirestore();
    }

    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    Widget destination;
    if (user == null) {
      destination = const AuthScreen();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_seen') ?? false;
      destination = seen ? const MainScreen() : const OnboardingScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => destination,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF8A2BE2);

    return Scaffold(
      backgroundColor: const Color(0xFF120E1A), // Fondo oscuro de la app
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reemplaza este Icono por tu Image.asset('assets/logo.png') cuando lo tengas
            const Icon(Icons.rocket_launch, size: 100, color: primaryPurple),
            const SizedBox(height: 24),
            const Text(
              'NOTOVA',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: primaryPurple,
              ),
            ),

            // Saludo personalizado si el usuario ya estaba logueado
            if (_userName != null) ...[
              const SizedBox(height: 16),
              Text(
                'Hola, $_userName',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 48),

            // --- Barra de carga morada y blanca ---
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryPurple,
                  ), // Relleno morado
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
