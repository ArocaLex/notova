// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../l10n/app_strings.dart';
import '../repositories/audio_repository.dart';
import '../repositories/export_repository.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  static const _bgColor = Color(0xFF120E1A);
  static const _cardColor = Color(0xFF1E1926);
  static const _primaryPurple = Color(0xFF7B2CBF);
  static const _cyanAccent = Color(0xFFDEB7FF);

  final _audio = AudioRepository();
  final _export = ExportRepository();

  // Mapa de definiciones de badges: id → (icono, label, color)
  static const _badgeDefs = {
    'first_quest': (Icons.flag_rounded, 'Primera Quest', Color(0xFF7B2CBF)),
    'streak_3': (Icons.local_fire_department, 'Racha x3', Colors.orange),
    'streak_7': (Icons.whatshot, 'Racha x7', Colors.deepOrange),
    'nivel_3': (Icons.shield, 'Táctico', Color(0xFF2D5AF7)),
    'nivel_5': (Icons.star_rounded, 'Maestro', Color(0xFFDEB7FF)),
    'nivel_7': (Icons.emoji_events, 'SuperNotova', Colors.amber),
  };

  // ── Export sheet ─────────────────────────────────────────────────────────

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('EXPORTAR HISTORIAL',
                  style: TextStyle(
                      color: Color(0xFF988D9E),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 16),
            _ExportButton(
              icon: Icons.table_chart_outlined,
              label: 'Exportar como CSV',
              color: _cyanAccent,
              onTap: () => _doExport(sheetCtx, 'csv'),
            ),
            const SizedBox(height: 10),
            _ExportButton(
              icon: Icons.text_snippet_outlined,
              label: 'Exportar como TXT',
              color: const Color(0xFFDEB7FF),
              onTap: () => _doExport(sheetCtx, 'txt'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doExport(BuildContext sheetCtx, String format) async {
    Navigator.pop(sheetCtx);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Exportando…'),
      duration: Duration(seconds: 1),
      backgroundColor: Color(0xFF1E1A29),
    ));

    try {
      final path = format == 'csv'
          ? await _export.exportToCsv()
          : await _export.exportToTxt();

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Guardado en: $path'),
        backgroundColor: _primaryPurple,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Enviar al servidor',
          textColor: _cyanAccent,
          onPressed: () async {
            final ok = await _export.sendToApi(format);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? '¡Enviado correctamente!' : 'Error al enviar al servidor'),
              backgroundColor: ok ? Colors.green : Colors.redAccent,
            ));
          },
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Error al exportar: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // ── SFX dialog ────────────────────────────────────────────────────────────

  void _showSfxDialog() async {
    final current = await _audio.getSfxEnabled();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool sfxOn = current;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Ajustes de Sonido',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Efectos de sonido (SFX)',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Switch(
                  value: sfxOn,
                  activeColor: _primaryPurple,
                  onChanged: (val) {
                    setDialogState(() => sfxOn = val);
                    _audio.setSfxEnabled(val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar',
                    style: TextStyle(color: _primaryPurple)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Edit name dialog ──────────────────────────────────────────────────────

  void _showEditNameDialog() {
    final user = context.read<UserViewModel>().user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Nombre',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF120E1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                await context.read<UserViewModel>().updateName(name);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Settings sheet ────────────────────────────────────────────────────────

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('AJUSTES',
                  style: TextStyle(
                      color: Color(0xFF988D9E),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.edit_outlined,
              iconColor: Colors.white70,
              label: 'Editar Nombre',
              subtitle: 'Cambia tu nombre de perfil',
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog();
              },
            ),
            _SettingsTile(
              icon: Icons.file_download_outlined,
              iconColor: _cyanAccent,
              label: 'Exportar Quests',
              subtitle: 'Descarga tu historial en .csv / .txt',
              onTap: () {
                Navigator.pop(context);
                _showExportSheet();
              },
            ),
            _SettingsTile(
              icon: Icons.volume_up_outlined,
              iconColor: _primaryPurple,
              label: 'Ajustes de Sonido',
              subtitle: 'Activa o desactiva los SFX',
              onTap: () {
                Navigator.pop(context);
                _showSfxDialog();
              },
            ),
            _SettingsTile(
              icon: Icons.photo_library_outlined,
              iconColor: const Color(0xFFDEB7FF),
              label: 'Configurar Avatar',
              subtitle: 'Elige una imagen de tu galería',
              onTap: () async {
                Navigator.pop(context);
                try {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 512,
                  );
                  if (picked == null || !mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Subiendo avatar…'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF1E1A29),
                  ));
                  await context
                      .read<UserViewModel>()
                      .uploadAvatar(File(picked.path));
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(
                    content: Text('¡Avatar actualizado!'),
                    backgroundColor: Colors.green,
                  ));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error al subir avatar: $e'),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 5),
                  ));
                }
              },
            ),
            _SettingsTile(
              icon: Icons.language,
              iconColor: Colors.blueAccent,
              label: context.read<AppStrings>().get('language'),
              subtitle: context.read<AppStrings>().isSpanish
                  ? 'Español → English'
                  : 'English → Español',
              onTap: () {
                context.read<AppStrings>().toggle();
                Navigator.pop(context);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white10),
            ),
            _SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.redAccent,
              label: context.read<AppStrings>().get('logout'),
              subtitle: context.read<AppStrings>().get('logout_subtitle'),
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
        backgroundColor: _bgColor,
        body: Center(
            child: CircularProgressIndicator(color: _primaryPurple)),
      );
    }

    final user = userVM.user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
            child: Text('Cargando perfil…',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDEB7FF)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('Notova Profile',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFFDEB7FF))),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Color(0xFFDEB7FF)),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                        colors: [_primaryPurple, _cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: _primaryPurple.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2),
                        BoxShadow(
                            color: _cyanAccent.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 4),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: const Color(0xFF2A223E),
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white70)
                          : null,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                        color: _primaryPurple, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(5),
                    child: const Icon(Icons.check,
                        size: 14, color: Colors.white),
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
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _primaryPurple.withOpacity(0.3)),
              ),
              child: Text(
                '${user.rank.toUpperCase()} · NIVEL ${user.level}',
                style: const TextStyle(
                    color: Color(0xFFDEB7FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 28),

            // --- TARJETA DE EXPERIENCIA ---
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _primaryPurple.withOpacity(0.3), width: 1),
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
                          const Text('EXPERIENCIA',
                              style: TextStyle(
                                  color: Color(0xFF988D9E),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 10)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: _formatNumber(user.totalXpEver),
                                style: const TextStyle(
                                    color: Color(0xFFDEB7FF),
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (user.level < 7)
                                TextSpan(
                                  text: ' / ${_formatNumber(user.currentLevelMaxXp)} XP',
                                  style: const TextStyle(
                                      color: Color(0xFF988D9E),
                                      fontSize: 14),
                                )
                              else
                                const TextSpan(
                                  text: ' XP  🏆',
                                  style: TextStyle(
                                      color: Color(0xFF988D9E),
                                      fontSize: 14),
                                ),
                            ]),
                          ),
                        ],
                      ),
                      if (user.xpProgress >= 0.7 && user.level < 7)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('¡PRÓXIMO NIVEL!',
                              style: TextStyle(
                                  color: _cyanAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
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
                              colors: [_primaryPurple, _cyanAccent]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.level < 7
                        ? '${_formatNumber(user.xpRemaining)} XP para alcanzar ${_nextRankName(user.level)}'
                        : '¡Has alcanzado el nivel máximo! Estado SuperNotova.',
                    style: const TextStyle(
                        color: Color(0xFF988D9E),
                        fontStyle: FontStyle.italic,
                        fontSize: 11),
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
                    title: 'RANGO',
                    value: user.rank,
                    icon: Icons.military_tech,
                    iconColor: _primaryPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'XP TOTAL',
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
                    title: 'RACHA',
                    value: '${user.dayStreak} días',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'INSIGNIAS',
                    value: '${user.badgesCount}',
                    icon: Icons.shield_rounded,
                    iconColor: _cyanAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- BADGES DINÁMICOS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('INSIGNIAS',
                    style: TextStyle(
                        color: Color(0xFF988D9E),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _badgeDefs.entries.map((entry) {
                final id = entry.key;
                final (icon, label, color) = entry.value;
                final unlocked = user.badges.contains(id);
                return _buildBadgeItem(icon, label, color,
                    isLocked: !unlocked);
              }).toList(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _nextRankName(int currentLevel) {
    return UserModel.rankForLevel(currentLevel + 1);
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
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF988D9E),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isLocked ? Colors.transparent : color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: isLocked
                    ? Colors.grey.shade800
                    : color.withOpacity(0.5),
                width: 2),
          ),
          child: Icon(icon,
              color: isLocked ? Colors.grey.shade700 : color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: isLocked
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      ],
    );
  }
}

// ── Export button ─────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
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
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade700, size: 20),
          ],
        ),
      ),
    );
  }
}
