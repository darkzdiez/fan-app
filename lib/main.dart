import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/core/app_controller.dart';

/// Punto de entrada principal de la app.
///
/// Se inicializa Flutter, se recupera la sesión persistida si existe y recién
/// después se monta el árbol de widgets para evitar parpadeos de navegación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appController = await AppController.bootstrap();

  runApp(FanApp(controller: appController));
}
