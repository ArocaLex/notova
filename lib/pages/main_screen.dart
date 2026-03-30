// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'calendar_screen.dart';
import 'home_screen.dart';
import 'task_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Detecta el espacio que ocupan los botones del sistema (si el usuario los tiene)
    final systemBottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF15111D),
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: systemBottomPadding > 0 ? systemBottomPadding + 16 : 24,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centra la cápsula en la pantalla
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF1E1E1E,
                ).withOpacity(0.95), // Gris muy oscuro casi opaco
                borderRadius: BorderRadius.circular(40), // Forma de cápsula
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  // Brillo sutil superior para efecto cristal
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize
                    .min, // Hace que la caja solo ocupe lo necesario
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  const SizedBox(width: 4),
                  _buildNavItem(1, Icons.calendar_month_rounded, 'Dates'),
                  const SizedBox(width: 4),
                  _buildNavItem(2, Icons.check_circle_rounded, 'Quests'),
                  const SizedBox(width: 4),
                  _buildNavItem(3, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DEL BOTÓN ANIMADO ---
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const primaryPurple = Color(0xFF8A2BE2);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          // Fondo morado semitransparente si está seleccionado
          color: isSelected
              ? primaryPurple.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          // Borde morado sutil si está seleccionado
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
            // La magia de la expansión: El texto aparece o desaparece
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
                  : const SizedBox.shrink(), // No ocupa espacio si no está seleccionado
            ),
          ],
        ),
      ),
    );
  }
}
