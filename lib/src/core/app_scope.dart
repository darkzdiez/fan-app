import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// `InheritedNotifier` propio para evitar sumar Provider/Riverpod.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();

    assert(scope != null, 'AppScope no está disponible en este contexto.');

    return scope!.notifier!;
  }
}
