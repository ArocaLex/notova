// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../l10n/app_strings.dart';
import '../repositories/audio_repository.dart';
import '../repositories/export_repository.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../theme/app_colors.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

/// Pantalla de perfil del usuario.
///
/// Permite editar nombre y avatar, gestionar ajustes (audio/notificaciones)
/// y exportar el historial de quests mediante [ExportRepository].
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  static const _bgColor = AppColors.background;
  static const _cardColor = AppColors.card;
  static const _primaryPurple = AppColors.primaryPurple;
  static const _cyanAccent = AppColors.cyanAccent;

  static const _textPrimary = AppColors.textPrimary;
  static const _textSecondary = AppColors.textSecondary;
  static const _textMuted = AppColors.textMuted;

  final _audio = AudioRepository();
  final _export = ExportRepository();

  static const _badgeDefs = {
    'first_quest': (Icons.flag_rounded, 'badge_first_quest', Color(0xFF7B2CBF)),
    'streak_3': (Icons.local_fire_department, 'badge_streak_3', Colors.orange),
    'streak_7': (Icons.whatshot, 'badge_streak_7', Colors.deepOrange),
    'nivel_3': (Icons.shield, 'badge_nivel_3', Color(0xFF2D5AF7)),
    'nivel_5': (Icons.star_rounded, 'badge_nivel_5', Color(0xFFDEB7FF)),
    'nivel_7': (Icons.emoji_events, 'badge_nivel_7', Colors.amber),
  };

  void _showExportSheet() {
    final s = context.read<AppStrings>();
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(s.get('export_history'),
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 16),
            _ExportButton(
              icon: Icons.table_chart_outlined,
              label: s.get('export_csv'),
              color: _cyanAccent,
              onTap: () => _doExport(sheetCtx, 'csv'),
            ),
            const SizedBox(height: 10),
            _ExportButton(
              icon: Icons.text_snippet_outlined,
              label: s.get('export_txt'),
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

    final s = context.read<AppStrings>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(s.get('preparing_file')),
      duration: const Duration(seconds: 1),
      backgroundColor: const Color(0xFF1E1A29),
    ));

    try {
      await _export.shareExport(format);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(s.get('export_failed')),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _showSfxDialog() async {
    final current = await _audio.getSfxEnabled();
    if (!mounted) return;

    final s = context.read<AppStrings>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool sfxOn = current;
        return StatefulBuilder(
          builder: (builderContext, setDialogState) => AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(s.get('sound_settings'),
                style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.get('sfx_label'),
                    style: const TextStyle(color: _textMuted, fontSize: 14)),
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
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(s.get('close'),
                    style: const TextStyle(color: _primaryPurple)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditNameDialog() {
    final user = context.read<UserViewModel>().user;
    if (user == null) return;
    final s = context.read<AppStrings>();

    final nameCtrl = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.get('edit_name'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: s.get('your_name'),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.get('cancel'), style: const TextStyle(color: Colors.grey)),
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
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            child: Text(s.get('save'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final s = context.read<AppStrings>();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _primaryPurple.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.get('language'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _LanguageOption(
                flag: '🇪🇸',
                label: 'Español',
                isSelected: s.isSpanish,
                onTap: () {
                  context.read<AppStrings>().setLocale('es');
                  Navigator.pop(dialogContext);
                },
              ),
              const SizedBox(height: 10),
              _LanguageOption(
                flag: '🇬🇧',
                label: 'English',
                isSelected: !s.isSpanish,
                onTap: () {
                  context.read<AppStrings>().setLocale('en');
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final s = context.read<AppStrings>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.get('delete_account'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          s.get('delete_account_confirm'),
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AuthViewModel>().deleteAccount();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (pageContext, primaryAnimation, secondaryAnimation) =>
                        const WelcomeScreen(),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder:
                        (pageContext, primaryAnimation, secondaryAnimation, child) =>
                            FadeTransition(opacity: primaryAnimation, child: child),
                  ),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${s.get('delete_account_error')} $e'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            },
            child: Text(
              s.get('delete_account'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    final s = context.read<AppStrings>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(s.get('settings'),
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.edit_outlined,
              iconColor: Colors.white70,
              label: s.get('edit_name'),
              subtitle: s.get('edit_name_subtitle'),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog();
              },
            ),
            _SettingsTile(
              icon: Icons.file_download_outlined,
              iconColor: _cyanAccent,
              label: s.get('export_quests'),
              subtitle: s.get('export_subtitle'),
              onTap: () {
                Navigator.pop(context);
                _showExportSheet();
              },
            ),
            _SettingsTile(
              icon: Icons.volume_up_outlined,
              iconColor: _primaryPurple,
              label: s.get('sound_settings'),
              subtitle: s.get('sound_subtitle'),
              onTap: () {
                Navigator.pop(context);
                _showSfxDialog();
              },
            ),
            _SettingsTile(
              icon: Icons.photo_library_outlined,
              iconColor: const Color(0xFFDEB7FF),
              label: s.get('configure_avatar'),
              subtitle: s.get('avatar_subtitle'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 90,
                    maxWidth: 1024,
                  );
                  if (picked == null || !mounted) return;

                  final cropped = await ImageCropper().cropImage(
                    sourcePath: picked.path,
                    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: s.isSpanish ? 'Recortar Foto' : 'Crop Photo',
                        toolbarColor: const Color(0xFF120E1A),
                        toolbarWidgetColor: Colors.white,
                        activeControlsWidgetColor: const Color(0xFF7B2CBF),
                        backgroundColor: const Color(0xFF120E1A),
                        dimmedLayerColor: const Color(0xFF120E1A),
                        initAspectRatio: CropAspectRatioPreset.square,
                        lockAspectRatio: true,
                        statusBarColor: const Color(0xFF120E1A),
                      ),
                      IOSUiSettings(
                        title: s.isSpanish ? 'Recortar' : 'Crop',
                        cancelButtonTitle: s.isSpanish ? 'Cancelar' : 'Cancel',
                        doneButtonTitle: s.isSpanish ? 'Listo' : 'Done',
                        aspectRatioLockEnabled: true,
                        resetAspectRatioEnabled: false,
                      ),
                    ],
                  );
                  if (cropped == null || !mounted) return;

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(SnackBar(
                    content: Text(s.get('uploading_avatar')),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF1E1A29),
                  ));
                  await context
                      .read<UserViewModel>()
                      .uploadAvatar(File(cropped.path));
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text(s.get('avatar_updated')),
                    backgroundColor: Colors.green,
                  ));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${s.get('avatar_error')} $e'),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 5),
                  ));
                }
              },
            ),
            _SettingsTile(
              icon: Icons.language,
              iconColor: Colors.blueAccent,
              label: s.get('language'),
              subtitle: s.isSpanish ? 'Español / English' : 'English / Español',
              onTap: () {
                Navigator.pop(context);
                _showLanguageDialog();
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white10),
            ),
            _SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.orangeAccent,
              label: s.get('logout'),
              subtitle: s.get('logout_subtitle'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthViewModel>().signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (pageContext, primaryAnimation, secondaryAnimation) =>
                        const WelcomeScreen(),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder:
                        (pageContext, primaryAnimation, secondaryAnimation, child) =>
                            FadeTransition(opacity: primaryAnimation, child: child),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 4),
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.redAccent,
              label: s.get('delete_account'),
              subtitle: s.get('delete_account_subtitle'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog();
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final s = context.watch<AppStrings>();
    final navHeight = MainScreen.navBarHeight(context);

    if (userVM.isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: _primaryPurple),
                const SizedBox(height: 16),
                Text(s.get('loading_profile'),
                    style: const TextStyle(color: Colors.grey)),
              ],
            )),
      );
    }

    final user = userVM.user;
    if (user == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
            child: Text(s.get('loading_profile'),
                style: const TextStyle(color: Colors.grey))),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(s.get('profile'),
            style: const TextStyle(
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
            Center(
              child: GestureDetector(
                onLongPress: () {
                  final img = _avatarImage(userVM.localAvatarPath, user.avatarUrl);
                  if (img == null) return;
                  showDialog(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (dialogContext) => GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: Dialog(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            key: ValueKey('avatar_full_${userVM.avatarVersion}'),
                            radius: 140,
                            backgroundColor: const Color(0xFF2A223E),
                            backgroundImage: img,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: Container(
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
                          key: ValueKey('avatar_${userVM.avatarVersion}'),
                          radius: 56,
                          backgroundColor: const Color(0xFF2A223E),
                          backgroundImage: _avatarImage(
                              userVM.localAvatarPath, user.avatarUrl),
                          child: _avatarImage(
                                      userVM.localAvatarPath, user.avatarUrl) ==
                                  null
                              ? const Icon(Icons.person,
                                  size: 60, color: _textSecondary)
                              : null,
                        ),
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
            ),
            const SizedBox(height: 20),

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
                '${user.rank.toUpperCase()} · ${s.get('level')} ${user.level}',
                style: const TextStyle(
                    color: Color(0xFFDEB7FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 28),

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
                          Text(s.get('experience'),
                              style: const TextStyle(
                                  color: _textSecondary,
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
                                  text: ' / ${_formatNumber(user.nextLevelMinXp)} XP',
                                  style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 14),
                                )
                              else
                                const TextSpan(
                                  text: ' XP  🏆',
                                  style: TextStyle(
                                      color: _textSecondary,
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
                          child: Text(s.get('next_level'),
                              style: const TextStyle(
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
                        ? '${_formatNumber(user.xpRemaining)} ${s.get('xp_to_reach')} ${_nextRankName(user.level)}'
                        : s.get('max_level'),
                    style: const TextStyle(
                        color: _textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: s.get('rank'),
                    value: user.rank,
                    icon: Icons.military_tech,
                    iconColor: _primaryPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: s.get('total_xp'),
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
                    title: s.get('streak_label'),
                    value: '${user.dayStreak} ${s.get('days')}',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: s.get('badges_label'),
                    value: '${user.badgesCount}',
                    icon: Icons.shield_rounded,
                    iconColor: _cyanAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.get('badges'),
                    style: const TextStyle(
                        color: _textSecondary,
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
                final (icon, labelKey, color) = entry.value;
                final unlocked = user.badges.contains(id);
                return _buildBadgeItem(icon, s.get(labelKey), color,
                    isLocked: !unlocked);
              }).toList(),
            ),

            SizedBox(height: navHeight + 24),
          ],
        ),
      ),
    );
  }

  /// Devuelve la imagen apropiada para el avatar dando prioridad al archivo
  /// local (para reflejar el cambio al instante y funcionar sin conexión) y,
  /// como fallback, al `avatarUrl` remoto.
  ImageProvider? _avatarImage(String? localPath, String? remoteUrl) {
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) return FileImage(file);
    }
    if (remoteUrl == null || remoteUrl.isEmpty) return null;
    if (remoteUrl.startsWith('file://')) {
      final path = remoteUrl.substring('file://'.length);
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
      return null;
    }
    return NetworkImage(remoteUrl);
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
                  color: _textSecondary,
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

/// Botón de exportación con icono y etiqueta para el bottom sheet de exportar.
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

/// Opción de idioma con bandera para el diálogo de selección de idioma.
class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const _primaryPurple = AppColors.primaryPurple;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryPurple.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _primaryPurple.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _primaryPurple, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Tile genérico para el bottom sheet de ajustes de la pantalla de perfil.
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
