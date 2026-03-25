import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_controller.dart';
import 'core/app_scope.dart';
import 'core/app_environment.dart';
import 'core/app_theme.dart';
import 'core/widgets.dart';
import 'features/auth/login_screen.dart';
import 'features/organization/organization_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/reservations/bookable_module_screen.dart';
import 'features/reservations/reservations_models.dart';

class FanApp extends StatelessWidget {
  const FanApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'FAN App',
            debugShowCheckedModeBanner: false,
            locale: const Locale('es'),
            supportedLocales: const <Locale>[Locale('es')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: FanAppTheme.light(),
            home: const _RootScreen(),
          );
        },
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    if (controller.isBootstrapping) {
      return const Scaffold(
        body: FanLoadingView(message: 'Restaurando sesión y configuración...'),
      );
    }

    if (!controller.isAuthenticated) {
      return const LoginScreen();
    }

    return const _MainShell();
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  static const List<String> _titles = <String>[
    'Salas de reunión',
    'Equipos de laboratorio',
    'Mi incubada',
    'Mi perfil',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[controller.selectedTabIndex]),
        actions: <Widget>[
          IconButton(
            tooltip: 'Recargar sesión',
            onPressed: () async {
              await controller.refreshCurrentUser();
              await controller.refreshReservationConfig();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (AppEnvironment.usesDefaultApiBaseUrl)
            MaterialBanner(
              content: const Text(
                'La app está corriendo con la URL por defecto. Cambiala con --dart-define para usar otro ambiente.',
              ),
              actions: const <Widget>[SizedBox.shrink()],
            ),
          if (user.mustChangePassword)
            MaterialBanner(
              content: const Text(
                'Tu usuario requiere cambiar la contraseña. Lo podés hacer desde la pestaña Perfil.',
              ),
              actions: const <Widget>[SizedBox.shrink()],
            ),
          Expanded(
            child: IndexedStack(
              index: controller.selectedTabIndex,
              children: const <Widget>[
                BookableModuleScreen(type: BookableResourceType.meetingRoom),
                BookableModuleScreen(type: BookableResourceType.labEquipment),
                OrganizationScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedTabIndex,
        onDestinationSelected: controller.setSelectedTabIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Salas',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Equipos',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Incubada',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
