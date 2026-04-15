import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../features/auth/auth_repository.dart';
import 'api_client.dart';
import 'app_environment.dart';
import 'models.dart';
import 'session_storage.dart';

/// Estado global de la app.
///
/// Se encarga de:
/// - inicializar el cliente HTTP,
/// - recuperar la sesión persistida,
/// - exponer el usuario autenticado,
/// - traer la configuración general de reservas,
/// - y manejar login/logout.
class AppController extends ChangeNotifier {
  AppController._({
    required SessionStorage storage,
    required AuthRepository authRepository,
  }) : _storage = storage,
       _authRepository = authRepository;

  final SessionStorage _storage;
  final AuthRepository _authRepository;

  bool _isBootstrapping = true;
  String? _bootstrapError;
  AppSession? _session;
  ReservationConfig _reservationConfig = ReservationConfig.defaults();
  int _selectedTabIndex = 0;

  static Future<AppController> bootstrap() async {
    final apiClient = ApiClient(baseUrl: AppEnvironment.apiBaseUrl);
    final controller = AppController._(
      storage: SessionStorage(),
      authRepository: AuthRepository(apiClient),
    );

    await controller._restoreSessionIfPossible();
    controller._isBootstrapping = false;
    controller.notifyListeners();

    return controller;
  }

  bool get isBootstrapping => _isBootstrapping;
  bool get isAuthenticated => _session != null;
  String? get bootstrapError => _bootstrapError;
  AppUser? get currentUser => _session?.user;
  String? get authToken => _session?.token;
  ReservationConfig get reservationConfig => _reservationConfig;
  int get selectedTabIndex => _selectedTabIndex;
  ApiClient get apiClient => _authRepository.apiClient;

  void setSelectedTabIndex(int index) {
    if (_selectedTabIndex == index) {
      return;
    }

    _selectedTabIndex = index;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final session = await _authRepository.login(
      username: username,
      password: password,
    );

    await _applyAuthenticatedSession(session);
  }

  Future<bool> signInWithGoogle() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Google Sign-In solo está habilitado en Android en esta etapa.',
      );
    }

    if (!AppEnvironment.hasGoogleWebClientId) {
      throw StateError(
        'No hay un client ID web configurado para Google Sign-In.',
      );
    }

    final googleSignIn = _createGoogleSignIn();

    await _resetGoogleAccountSelection(googleSignIn);

    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return false;
    }

    try {
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken?.trim() ?? '';

      if (idToken.isEmpty) {
        throw StateError(
          'Google no devolvió un token de identidad válido para continuar.',
        );
      }

      final session = await _authRepository.loginWithGoogle(idToken: idToken);

      await _applyAuthenticatedSession(session);

      return true;
    } catch (_) {
      await _resetGoogleAccountSelection(googleSignIn);
      rethrow;
    }
  }

  GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: const <String>['email'],
      serverClientId: AppEnvironment.googleWebClientId,
    );
  }

  Future<void> _resetGoogleAccountSelection(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signOut();
    } catch (_) {
      // Ignorado: si no había una cuenta previa elegida, no hace falta actuar.
    }
  }

  Future<void> _applyAuthenticatedSession(AppSession session) async {
    apiClient.authToken = session.token;

    final reservationConfig = await _authRepository.fetchReservationConfig();

    _session = AppSession(token: session.token, user: session.user);
    _reservationConfig = reservationConfig;
    _bootstrapError = null;

    await _storage.save(_session!);
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    if (!isAuthenticated) {
      return;
    }

    final user = await _authRepository.fetchCurrentUser();
    _session = AppSession(token: _session!.token, user: user);
    await _storage.save(_session!);
    notifyListeners();
  }

  Future<void> refreshReservationConfig() async {
    if (!isAuthenticated) {
      return;
    }

    _reservationConfig = await _authRepository.fetchReservationConfig();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (isAuthenticated) {
        await _authRepository.logout();
      }
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _session = null;
    _reservationConfig = ReservationConfig.defaults();
    _selectedTabIndex = 0;
    _bootstrapError = null;
    apiClient.authToken = null;
    await _storage.clear();
    notifyListeners();
  }

  Future<void> _restoreSessionIfPossible() async {
    try {
      final storedSession = await _storage.load();

      if (storedSession == null) {
        return;
      }

      apiClient.authToken = storedSession.token;

      final user = await _authRepository.fetchCurrentUser();
      final reservationConfig = await _authRepository.fetchReservationConfig();

      _session = AppSession(token: storedSession.token, user: user);
      _reservationConfig = reservationConfig;
      await _storage.save(_session!);
    } on ApiException catch (error) {
      _bootstrapError = error.message;
      await clearSession();
    } catch (_) {
      _bootstrapError = 'No se pudo restaurar la sesión guardada.';
      await clearSession();
    }
  }
}
