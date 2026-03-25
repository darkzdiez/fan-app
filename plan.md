# Plan de implementación FAN App (Flutter)

## Objetivo
Crear una app Flutter multiplataforma (iOS, Android y Web) orientada a incubadas, con autenticación contra la API FAN y soporte para perfil, datos de incubada, reservas de salas y reservas de equipos.

## Tareas
- [x] Relevar APIs, rutas y reglas de negocio del sistema actual.
- [x] Verificar e instalar toolchain de Flutter/Dart y dependencias de sistema necesarias para desarrollo y prueba.
- [x] Instalar todas las dependencias necesarias para desarrollo y prueba, incluyendo Flutter SDK, Android Studio, y cualquier otra herramienta relevante.
- [x] Crear el proyecto Flutter base en `/home/dev/work/fan-app` con estructura vanilla, mínima cantidad de dependencias y documentación inicial.
- [x] Implementar capa de configuración, cliente HTTP y persistencia segura de sesión/token.
- [x] Implementar autenticación contra `/api/external/auth/login`, restauración de sesión y logout.
- [x] Implementar módulo de perfil: ver/editar perfil y cambiar contraseña.
- [x] Implementar módulo de incubada: ver/editar datos de la organización.
- [x] Implementar módulo de reservas de salas: listado, detalle, disponibilidad, mis reservas, crear, cancelar y calendario.
- [x] Implementar módulo de reservas de equipos: listado, detalle, disponibilidad, mis reservas, crear, cancelar y calendario.
- [x] Documentar arquitectura, setup, decisiones técnicas y flujo de uso para desarrollo/compilación.
- [x] Probar la app en las plataformas disponibles y ajustar errores encontrados.
- [x] Dejar checklist final y marcar tareas completadas.

## Próxima iteración: validación comparativa con la app actual
- [x] Ingresar con Chrome MCP a la app web actual `https://alfonzo-work.osole.com.ar:8448/` usando las credenciales provistas por el usuario, sin persistirlas en archivos del proyecto.
- [x] Ingresar con Chrome MCP a la app Flutter servida en `http://127.0.0.1:18081/` usando las mismas credenciales y verificar que el login, la restauración de sesión y el logout funcionen correctamente.
- [x] Comparar el flujo de edición de perfil de la web actual (`/profile`) con la pantalla de perfil de Flutter y ajustar diferencias funcionales o de UX para acercar la experiencia.
- [x] Probar una reserva de sala de reunión end-to-end en Flutter y verificarla también en la web actual, validando disponibilidad, creación y visualización en mis reservas.
- [x] Probar una reserva de equipo de laboratorio end-to-end en Flutter y verificarla también en la web actual, validando disponibilidad, creación y visualización en mis reservas.
- [x] Registrar gaps funcionales o de experiencia detectados durante la comparación y aplicar los ajustes necesarios para que la experiencia de la app Flutter quede lo más parecida posible a la app existente.
- [x] Mejorar la accesibilidad del modal de cancelación en Flutter y verificar una cancelación completa con MCP puro.
## Notas
- Priorizar Flutter vanilla y evitar dependencias innecesarias.
- Documentar ampliamente en código y en archivos Markdown.
- Usar la API autenticada recién implementada en FAN.
- Endpoints confirmados para la app: `/api/external/auth/*`, `/api/profile`, `/api/profile/change-password`, `/api/incubada`, `/api/config-general`, y los endpoints de reservas de salas/equipos para incubadas.
- Toolchain instalado y validado: Flutter 3.41.5, Dart 3.11.3, Java 17, Android SDK 36, Chrome para Web y Linux toolchain.
- URL base validada para pruebas y builds: `https://alfonzo-work.osole.com.ar:8448/api`.
- Validaciones ejecutadas: `flutter analyze`, `flutter test`, login real con bearer token contra `/api/profile`, `flutter build web` y `flutter build apk --debug`.
- Artefactos generados: `build/web/` y `build/app/outputs/flutter-apk/app-debug.apk`.
- La compilación de iOS queda lista a nivel de código fuente, pero debe ejecutarse en un equipo con macOS.
- La nueva ronda de QA debe tomar como referencia principal la experiencia de incubada en la web actual.
- No guardar usuarios ni contraseñas en el plan; usar las credenciales provistas por el usuario solo durante la prueba manual.
- En la comparación real se corrigió un bug importante: los listados de recursos en Flutter no debían usar slash final (`/meeting-room` y `/lab-equipment`).
- También se alineó la UX con la web agregando confirmación antes de guardar perfil/cambiar contraseña y ajustando tabs de reservas.
- En Chrome MCP fue necesario aceptar el certificado del backend en el mismo `isolatedContext` usado por la app Flutter.
- Las reservas creadas durante la validación MCP (`meeting_room_reservation #498` y `lab_equipment_reservation #123`) se cancelaron al final por API para no dejar datos de prueba activos.
- Luego de mejorar el modal de cancelación, también se probó una cancelación real desde Flutter con MCP puro sobre la reserva `meeting_room_reservation #500`, y la web actual reflejó el cambio correctamente.
- La app recibió una primera mejora visual para acercarla más a la web actual: app bar oscuro, acento azul FAN, fondos menos planos, tarjetas con mejor contraste y login con branding más marcado.
