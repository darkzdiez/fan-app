import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Persistencia ultra simple de sesión.
///
/// Se usa `shared_preferences` porque funciona en Android, iOS y Web sin sumar
/// una capa extra de complejidad. La contracara es que no es un cofre seguro,
/// así que esto queda documentado explícitamente en README/arquitectura.
class SessionStorage {
  static const String _sessionKey = 'fan_app.session';

  Future<AppSession?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSession = preferences.getString(_sessionKey);

    if (rawSession == null || rawSession.isEmpty) {
      return null;
    }

    return AppSession.decode(rawSession);
  }

  Future<void> save(AppSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, session.encode());
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }
}
