import 'package:flutter/material.dart';

import '../../core/app_environment.dart';
import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await AppScope.of(context).login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = collapseApiException(error);
      });
    } catch (error) {
      setState(() {
        _errorMessage = describeUnexpectedError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2F3135),
              Color(0xFFF2F5F8),
            ],
            stops: <double>[0, 0.36],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: scheme.primary,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.hub_outlined, size: 28),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'FAN App',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acceso para incubadas a perfil, organización y reservas.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (AppEnvironment.usesDefaultApiBaseUrl)
                      const FanErrorBanner(
                        message:
                            'La app está usando la URL por defecto http://127.0.0.1:8000/api. El puerto 3000 solo publica el frontend. Para este ambiente ejecutala con flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api',
                      ),
                    if (AppEnvironment.usesDefaultApiBaseUrl)
                      const SizedBox(height: 16),
                    SectionCard(
                      title: 'Iniciar sesión',
                      subtitle: 'Autenticación contra la API externa de FAN.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario o correo electrónico',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                            ),
                            onSubmitted: (_) => _isSubmitting ? null : _submit(),
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null) ...<Widget>[
                            FanErrorBanner(message: _errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _isSubmitting
                                  ? 'Validando credenciales...'
                                  : 'Iniciar sesión',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'API actual: ${AppEnvironment.apiBaseUrl}',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
