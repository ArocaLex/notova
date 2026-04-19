import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona la reproducción de efectos de sonido (SFX) de la app.
///
/// Los sonidos se activan en:
///   - Completar una tarea  → task_complete.mp3
///   - Subir de nivel       → level_up.mp3
///
/// El usuario puede desactivar el audio desde Ajustes de Perfil.
/// La preferencia se persiste en SharedPreferences bajo la clave 'sfx_enabled'.
class AudioRepository {
  static final AudioRepository _instance = AudioRepository._internal();
  factory AudioRepository() => _instance;
  AudioRepository._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _sfxEnabled = true;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _initialized = true;
  }

  /// Reproduce el SFX asociado a completar una quest.
  ///
  /// No tiene efecto si el usuario desactivó los sonidos mediante
  /// [setSfxEnabled].
  Future<void> playTaskComplete() async {
    await _ensureInit();
    if (!_sfxEnabled) return;
    await _player.play(AssetSource('audio/task_complete.mp3'));
  }

  /// Reproduce el SFX asociado a subir de nivel.
  ///
  /// No tiene efecto si el usuario desactivó los sonidos mediante
  /// [setSfxEnabled].
  Future<void> playLevelUp() async {
    await _ensureInit();
    if (!_sfxEnabled) return;
    await _player.play(AssetSource('audio/level_up.mp3'));
  }

  /// Activa o desactiva los efectos de sonido.
  ///
  /// Persiste la preferencia en [SharedPreferences] bajo la clave
  /// `sfx_enabled`.
  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', value);
  }

  /// Indica si los efectos de sonido están activos en esta sesión.
  bool get sfxEnabled => _sfxEnabled;

  /// Carga la preferencia actual (útil para leer antes de mostrar el toggle en UI).
  Future<bool> getSfxEnabled() async {
    await _ensureInit();
    return _sfxEnabled;
  }
}
