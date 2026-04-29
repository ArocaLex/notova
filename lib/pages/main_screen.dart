// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../viewmodel/calendar_viewmodel.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'task_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal de la app con navegación inferior.
///
/// Aloja las pantallas base (Home, Calendar, Quests y Profile) y mantiene el
/// estado de navegación usando un `IndexedStack` para preservar el estado de
/// cada pestaña.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  /// Altura total de la cápsula de navegación desde la parte inferior
  /// de la pantalla, incluyendo el inset del sistema (home indicator /
  /// barra de 3 botones).
  static double navBarHeight(BuildContext context) {
    final sys = MediaQuery.of(context).viewPadding.bottom;
    return _capsuleHeight + (sys > 0 ? sys + 16.0 : 24.0);
  }

  /// Distancia desde la parte inferior de la pantalla a la que debe
  /// posicionarse la parte inferior de un FAB para quedar por encima
  /// de la cápsula con un margen de 12 px.
  static double fabBottom(BuildContext context) =>
      navBarHeight(context) + 12.0;

  /// Altura del contenedor de la cápsula de navegación.
  static const double _capsuleHeight = 66.0;

  @override
  MainScreenState createState() => MainScreenState();
}

/// Estado de [MainScreen].
///
/// Usa [WidgetsBindingObserver] para detectar el retorno de la app desde
/// background y reposicionar el calendario en el día de hoy cuando la
/// pestaña activa es la de calendario.
class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  /// Índice de la pestaña del calendario dentro de [_screens].
  static const int _calendarTabIndex = 1;

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver a primer plano con la pestaña calendario activa, reposiciona
  /// el calendario en el día de hoy para que no quede "atascado" en una
  /// fecha previamente seleccionada.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _currentIndex == _calendarTabIndex) {
      context.read<CalendarViewModel>().resetToToday();
    }
  }

  /// Cambia la pestaña activa y, al entrar al calendario desde otra pestaña,
  /// reposiciona la vista en el día de hoy.
  void _onTabTap(int index) {
    if (index == _calendarTabIndex && _currentIndex != _calendarTabIndex) {
      context.read<CalendarViewModel>().resetToToday();
    }
    setState(() => _currentIndex = index);
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Salir de Notova',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          '¿Seguro que quieres salir?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Salir',
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStrings>();
    final sys = MediaQuery.of(context).viewPadding.bottom;
    final navBottom = sys > 0 ? sys + 16.0 : 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(bottom: navBottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 1,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, s.get('nav_home')),
                        const SizedBox(width: 4),
                        _buildNavItem(
                            1, Icons.calendar_month_rounded, s.get('nav_calendar')),
                        const SizedBox(width: 4),
                        _buildNavItem(
                            2, Icons.check_circle_rounded, s.get('nav_quests')),
                        const SizedBox(width: 4),
                        _buildNavItem(
                            3, Icons.person_rounded, s.get('nav_profile')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const primaryPurple = AppColors.primaryPurple;

    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryPurple.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: primaryPurple.withOpacity(0.5), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryPurple : Colors.grey.shade600,
              size: 26,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
