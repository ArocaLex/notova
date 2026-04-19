// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_screen.dart';

/// Onboarding inicial que se muestra una única vez.
///
/// Persiste la preferencia `onboarding_seen` en [SharedPreferences] y navega a
/// [MainScreen] al finalizar u omitir.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _bgColor = Color(0xFF120E1A);
  static const _primaryPurple = Color(0xFF7B2CBF);

  final _pages = const [
    _OnboardingPage(
      icon: Icons.bolt,
      iconColor: Color(0xFFDEB7FF),
      title: 'Bienvenido a Notova',
      subtitle:
          'Convierte tus tareas en Quests.\nGana XP, sube de nivel y construye hábitos duraderos.',
    ),
    _OnboardingPage(
      icon: Icons.military_tech_rounded,
      iconColor: Color(0xFFDEB7FF),
      title: 'Sistema de Rangos',
      subtitle:
          'Novato → Aspirante → Táctico → Ninja → Maestro → Leyenda → SuperNotova\n\nCada Quest completada te acerca al siguiente nivel.',
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      iconColor: Color(0xFF7B2CBF),
      title: 'Conecta tu Calendario',
      subtitle:
          'Sincroniza Google Calendar para ver tus eventos y Quests en un solo lugar.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (ctx, anim, s, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Omitir',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? _primaryPurple : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: _primaryPurple.withOpacity(0.4),
                  ),
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Siguiente' : 'Comenzar',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.2),
                  iconColor.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 56),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                height: 1.6),
          ),
        ],
      ),
    );
  }
}
