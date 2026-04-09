import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_controller.dart';
import 'core/app_scope.dart';
import 'core/app_environment.dart';
import 'core/branding.dart';
import 'core/models.dart';
import 'core/app_theme.dart';
import 'core/widgets.dart';
import 'features/auth/login_screen.dart';
import 'features/organization/organization_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/reservations/bookable_module_screen.dart';
import 'features/reservations/qr_scanner_flow.dart';
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
            title: FanBranding.appName,
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

  bool _hasQrAccess(AppUser user) {
    return user.userCan(bookableResourcesQrScanPermission);
  }

  int _navigationIndexForTab(int tabIndex, bool hasQrAccess) {
    if (!hasQrAccess) {
      return tabIndex;
    }

    if (tabIndex < 2) {
      return tabIndex;
    }

    return tabIndex + 1;
  }

  int _tabIndexForNavigationIndex(int navigationIndex, bool hasQrAccess) {
    if (!hasQrAccess) {
      return navigationIndex;
    }

    if (navigationIndex < 2) {
      return navigationIndex;
    }

    return navigationIndex - 1;
  }

  void _handleDestinationSelected(
    BuildContext context,
    int index,
    bool hasQrAccess,
  ) {
    final controller = AppScope.of(context);

    if (hasQrAccess && index == 2) {
      unawaited(startQrReservationFlow(context));
      return;
    }

    controller.setSelectedTabIndex(
      _tabIndexForNavigationIndex(index, hasQrAccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser!;
    final hasQrAccess = _hasQrAccess(user);
    final selectedNavigationIndex = _navigationIndexForTab(
      controller.selectedTabIndex,
      hasQrAccess,
    );

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.meeting_room_outlined),
        selectedIcon: Icon(Icons.meeting_room),
        label: 'Salas',
      ),
      const NavigationDestination(
        icon: Icon(Icons.science_outlined),
        selectedIcon: Icon(Icons.science),
        label: 'Equipos',
      ),
      if (hasQrAccess)
        const NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: 'QR',
        ),
      const NavigationDestination(
        icon: Icon(Icons.apartment_outlined),
        selectedIcon: Icon(Icons.apartment),
        label: 'Incubada',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

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
        selectedIndex: selectedNavigationIndex,
        onDestinationSelected: (index) =>
            _handleDestinationSelected(context, index, hasQrAccess),
        destinations: destinations,
      ),
    );
  }
}
