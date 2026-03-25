import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/models.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  String? _profileError;
  String? _passwordError;

  ProfileRepository get _repository =>
      ProfileRepository(AppScope.of(context).apiClient);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _profileError = null;
    });

    try {
      final profile = await _repository.fetchProfile();
      _nameController.text = profile.name;
      _usernameController.text = profile.username;
      _emailController.text = profile.email;
    } on ApiException catch (error) {
      _profileError = collapseApiException(error);
    } catch (_) {
      _profileError = 'No se pudo cargar el perfil actual.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final appController = AppScope.of(context);

    final confirmed = await _confirmAction(
      title: 'Actualizar perfil',
      message:
          '¿Estás seguro de que deseás actualizar tu información de perfil?',
      confirmLabel: 'Aceptar',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _isSavingProfile = true;
      _profileError = null;
    });

    try {
      await _repository.saveProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );
      await appController.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente.')),
        );
      }
    } on ApiException catch (error) {
      setState(() {
        _profileError = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _profileError = 'No se pudo guardar el perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final appController = AppScope.of(context);

    if (_passwordController.text.isEmpty ||
        _passwordConfirmationController.text.isEmpty) {
      setState(() {
        _passwordError = 'Completá ambos campos de contraseña.';
      });
      return;
    }

    if (_passwordController.text != _passwordConfirmationController.text) {
      setState(() {
        _passwordError = 'La confirmación no coincide con la contraseña.';
      });
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Cambiar contraseña',
      message:
          '¿Estás seguro de que deseás actualizar la contraseña de este usuario?',
      confirmLabel: 'Aceptar',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordError = null;
    });

    try {
      await _repository.changePassword(
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );
      _passwordController.clear();
      _passwordConfirmationController.clear();
      await appController.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La contraseña se actualizó correctamente.'),
          ),
        );
      }
    } on ApiException catch (error) {
      setState(() {
        _passwordError = collapseApiException(error);
      });
    } catch (_) {
      setState(() {
        _passwordError = 'No se pudo cambiar la contraseña.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AppScope.of(context).currentUser;

    if (_isLoading) {
      return const FanLoadingView(message: 'Cargando perfil...');
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SectionCard(
            title: 'Sesión actual',
            subtitle: 'Resumen útil para validar el contexto de la app.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Usuario: ${currentUser?.name ?? '-'}'),
                Text('Correo: ${currentUser?.email ?? '-'}'),
                Text('Organización: ${currentUser?.organizationName ?? '-'}'),
                Text('Tipo: ${currentUser?.organizationTypeName ?? '-'}'),
              ],
            ),
          ),
          SectionCard(
            title: 'Editar perfil',
            subtitle:
                'Este formulario utiliza `/api/profile` del backend compartido.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                if (_profileError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  FanErrorBanner(message: _profileError!),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: _isSavingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSavingProfile ? 'Guardando...' : 'Guardar perfil',
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Cambiar contraseña',
            subtitle: 'La API espera `password` y `password_confirmation`.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Mínimo 8 caracteres.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordConfirmationController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                  ),
                ),
                if (_passwordError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  FanErrorBanner(message: _passwordError!),
                ],
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  icon: _isChangingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset),
                  label: Text(
                    _isChangingPassword
                        ? 'Actualizando contraseña...'
                        : 'Cambiar contraseña',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
