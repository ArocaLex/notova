import 'package:shared_preferences/shared_preferences.dart';

/// Contador diario de tareas completadas por usuario.
///
/// El contador solo puede subir (completar tareas). Borrar tareas no lo reduce.
/// Se reinicia automáticamente cuando el día cambia (detección lazy al leer).
/// Persiste en SharedPreferences con clave por usuario.
class DailyCounterService {
  static String _countKey(String uid) => '${uid}_daily_count';
  static String _dateKey(String uid) => '${uid}_daily_date';

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Devuelve el contador de hoy. Si la fecha almacenada difiere de hoy,
  /// resetea el contador a 0 y persiste la nueva fecha.
  Future<int> getCount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_dateKey(uid));
    final today = _todayStr();

    if (storedDate != today) {
      await prefs.setInt(_countKey(uid), 0);
      await prefs.setString(_dateKey(uid), today);
      return 0;
    }

    return prefs.getInt(_countKey(uid)) ?? 0;
  }

  /// Incrementa el contador en 1 y persiste.
  Future<void> increment(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final storedDate = prefs.getString(_dateKey(uid));

    int current = (storedDate == today) ? (prefs.getInt(_countKey(uid)) ?? 0) : 0;
    await prefs.setInt(_countKey(uid), current + 1);
    await prefs.setString(_dateKey(uid), today);
  }

  /// Fuerza un reset a 0 para el usuario dado (llamado desde el timer de medianoche).
  Future<void> resetForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey(uid), 0);
    await prefs.setString(_dateKey(uid), _todayStr());
  }
}
