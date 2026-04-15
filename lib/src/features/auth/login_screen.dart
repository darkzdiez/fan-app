import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_environment.dart';
import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/branding.dart';
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
  bool _isGoogleSubmitting = false;
  String? _errorMessage;

  bool get _supportsGoogleSignIn =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      AppEnvironment.hasGoogleWebClientId;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _isGoogleSubmitting = false;
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
          _isGoogleSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isSubmitting = true;
      _isGoogleSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await AppScope.of(context).signInWithGoogle();

      if (!authenticated || !mounted) {
        return;
      }
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
          _isGoogleSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF2F3135),
                  Color(0xFF49505A),
                  Color(0xFFF2F5F8),
                ],
                stops: <double>[0, 0.22, 0.7],
              ),
            ),
          ),
          const _LoginBackgroundOrb(
            top: -80,
            left: -70,
            size: 240,
            color: Color(0x220B9BCB),
          ),
          const _LoginBackgroundOrb(
            top: 88,
            right: -90,
            size: 220,
            color: Color(0x14FFFFFF),
          ),
          const _LoginBackgroundOrb(
            bottom: -120,
            left: 30,
            size: 260,
            color: Color(0x180B9BCB),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFFFFFFFF),
                                Color(0xFFF8FBFD),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x24000000),
                                blurRadius: 34,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                top: -54,
                                right: -36,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: FanAppTheme.brandBlue.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -52,
                                left: -24,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0x0D18212B),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 26,
                                ),
                                child: Center(child: FanBrandLogo(height: 154)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (AppEnvironment.usesDefaultApiBaseUrl)
                        const FanErrorBanner(
                          message:
                              'La app está usando la URL por defecto http://127.0.0.1:8000/api. El puerto 3000 solo publica el frontend. Para este ambiente ejecutala con flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api',
                        ),
                      if (AppEnvironment.usesDefaultApiBaseUrl)
                        const SizedBox(height: 18),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x15000000),
                              blurRadius: 32,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: <Color>[
                                            Color(0xFF1AB7E7),
                                            Color(0xFF0B9BCB),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Iniciar sesión',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: FanAppTheme.ink,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ingresá con tus credenciales para acceder a reservas, perfil e información de tu incubada.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: FanAppTheme.muted,
                                                  height: 1.45,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const <String>[
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: 'Usuario o correo electrónico',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const <String>[
                                    AutofillHints.password,
                                  ],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    hintText: 'Contraseña',
                                    prefixIcon: Icon(Icons.key_outlined),
                                  ),
                                  onSubmitted: (_) =>
                                      _isSubmitting ? null : _submit(),
                                ),
                                const SizedBox(height: 16),
                                if (_errorMessage != null) ...<Widget>[
                                  FanErrorBanner(message: _errorMessage!),
                                  const SizedBox(height: 18),
                                ],
                                SizedBox(
                                  height: 56,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      textStyle: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    onPressed: _isSubmitting ? null : _submit,
                                    icon: _isSubmitting && !_isGoogleSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.login_rounded),
                                    label: Text(
                                      _isSubmitting && !_isGoogleSubmitting
                                          ? 'Validando credenciales...'
                                          : 'Iniciar sesión',
                                    ),
                                  ),
                                ),
                                if (_supportsGoogleSignIn) ...<Widget>[
                                  const SizedBox(height: 18),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Divider(
                                          color: scheme.outline.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'o continuar con',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color: FanAppTheme.muted,
                                                letterSpacing: 0.3,
                                              ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: scheme.outline.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: scheme.outline.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                        textStyle: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      onPressed: _isSubmitting
                                          ? null
                                          : _submitGoogle,
                                      icon: _isSubmitting && _isGoogleSubmitting
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: scheme.primary,
                                              ),
                                            )
                                          : const _GoogleBadge(),
                                      label: Text(
                                        _isSubmitting && _isGoogleSubmitting
                                            ? 'Conectando con Google...'
                                            : 'Continuar con Google',
                                      ),
                                    ),
                                  ),
                                ],
                                if (AppEnvironment
                                    .showDeveloperAnnotations) ...<Widget>[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FAFC),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: scheme.outline.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Icon(
                                          Icons.cloud_outlined,
                                          size: 18,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'API actual',
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: FanAppTheme.muted,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                AppEnvironment.apiBaseUrl,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: FanAppTheme.ink,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6DCE3)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LoginBackgroundOrb extends StatelessWidget {
  const _LoginBackgroundOrb({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: SizedBox(width: size, height: size),
        ),
      ),
    );
  }
}
