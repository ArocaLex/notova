// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  static const bgColor = Color(0xFF15111D);
  static const cardColor = Color(0xFF1E1926);
  static const primaryPurple = Color(0xFF7B2CBF);
  static const cyanAccent = Color(0xFF00E5FF);

  File? _avatarFile;

  // ── Settings sheet ────────────────────────────────────────────────────────

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AJUSTES',
                style: TextStyle(
                  color: Color(0xFF988D9E),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.file_download_outlined,
              iconColor: cyanAccent,
              label: 'Exportar Quests',
              subtitle: 'Descarga tu historial en .csv / .txt',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exportación disponible próximamente'),
                    backgroundColor: Color(0xFF1E1A29),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.volume_up_outlined,
              iconColor: primaryPurple,
              label: 'Ajustes de Sonido',
              subtitle: 'Activa o desactiva los SFX',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajustes de sonido próximamente'),
                    backgroundColor: Color(0xFF1E1A29),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.photo_library_outlined,
              iconColor: const Color(0xFFDEB7FF),
              label: 'Configurar Avatar',
              subtitle: 'Elige una imagen de tu galería',
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 512,
                );
                if (picked != null && mounted) {
                  setState(() => _avatarFile = File(picked.path));
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white10),
            ),
            _SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.redAccent,
              label: 'Cerrar Sesión',
              subtitle: 'Salir de tu cuenta Notova',
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthViewModel>().signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (ctx, a1, a2) => const AuthScreen(),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder: (ctx, anim, s, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();

    if (userVM.isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    final user = userVM.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('Cargando perfil...', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDEB7FF)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          'Notova Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFFDEB7FF),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFDEB7FF)),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- AVATAR CON GLOW ---
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primaryPurple, cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: cyanAccent.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFF2A223E),
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : null,
                      child: _avatarFile == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- NOMBRE Y RANGO ---
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Text(
                '${user.rank.toUpperCase()} · LEVEL ${user.level}',
                style: const TextStyle(
                  color: Color(0xFFDEB7FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // --- TARJETA DE EXPERIENCIA ---
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXPERIENCE',
                            style: TextStyle(
                              color: Color(0xFF988D9E),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatNumber(user.currentXp),
                                  style: const TextStyle(
                                    color: Color(0xFFDEB7FF),
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${_formatNumber(user.totalXp)} XP',
                                  style: const TextStyle(
                                    color: Color(0xFF988D9E),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (user.xpProgress >= 0.7)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LEVEL UP SOON',
                            style: TextStyle(
                              color: cyanAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: user.xpProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [primaryPurple, cyanAccent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_formatNumber(user.xpRemaining)} XP remaining to reach Level ${user.level + 1}',
                    style: const TextStyle(
                      color: Color(0xFF988D9E),
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- GRID 2x2 ---
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'CURRENT RANK',
                    value: user.rank,
                    icon: Icons.military_tech,
                    iconColor: primaryPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'TOTAL XP',
                    value: _formatNumber(user.totalXpEver),
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFDEB7FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'DAY STREAK',
                    value: '${user.dayStreak} Days',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'BADGES',
                    value: '${user.badgesCount}',
                    icon: Icons.shield_rounded,
                    iconColor: cyanAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- RECENT BADGES ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT BADGES',
                  style: TextStyle(
                    color: Color(0xFF988D9E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                  ),
                  child: const Text(
                    'VIEW ALL',
                    style: TextStyle(
                      color: Color(0xFF7B2CBF),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadgeItem(Icons.menu_book, 'Scholar', primaryPurple),
                _buildBadgeItem(Icons.speed, 'Speed Runner', const Color(0xFF2D5AF7)),
                _buildBadgeItem(Icons.groups, 'Team Lead', const Color(0xFF10B981)),
                _buildBadgeItem(Icons.lock, 'Locked', Colors.grey.shade800, isLocked: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniBadge(Icons.auto_awesome, primaryPurple),
                const SizedBox(width: 12),
                _buildMiniBadge(Icons.bolt, cyanAccent),
                const SizedBox(width: 12),
                _buildMiniBadge(Icons.terminal, Colors.grey.shade600),
                const SizedBox(width: 12),
                _buildMiniBadge(Icons.emoji_events, primaryPurple),
              ],
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF988D9E),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(
    IconData icon,
    String label,
    Color color, {
    bool isLocked = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isLocked ? Colors.transparent : color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: isLocked ? Colors.grey.shade800 : color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isLocked ? Colors.grey.shade700 : color,
            size: 26,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isLocked ? Colors.grey.shade700 : Colors.grey.shade400,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A29),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade700, size: 20),
          ],
        ),
      ),
    );
  }
}
