# Plan de implementación FAN App (Flutter)

## Objetivo
Crear una app Flutter multiplataforma (iOS, Android y Web) orientada a incubadas, con autenticación contra la API FAN y soporte para perfil, datos de incubada, reservas de salas y reservas de equipos.

## Tareas
- [x] Relevar APIs, rutas y reglas de negocio del sistema actual.
- [x] Verificar e instalar toolchain de Flutter/Dart y dependencias de sistema necesarias para desarrollo y prueba.
- [x] Instalar todas las dependencias necesarias para desarrollo y prueba, incluyendo Flutter SDK, Android Studio, y cualquier otra herramienta relevante.
- [ ] Crear el proyecto Flutter base en `/home/dev/work/fan-app` con estructura vanilla, mínima cantidad de dependencias y documentación inicial.
- [ ] Implementar capa de configuración, cliente HTTP y persistencia segura de sesión/token.
- [ ] Implementar autenticación contra `/api/external/auth/login`, restauración de sesión y logout.
- [ ] Implementar módulo de perfil: ver/editar perfil y cambiar contraseña.
- [ ] Implementar módulo de incubada: ver/editar datos de la organización.
- [ ] Implementar módulo de reservas de salas: listado, detalle, disponibilidad, mis reservas, crear, cancelar y calendario.
- [ ] Implementar módulo de reservas de equipos: listado, detalle, disponibilidad, mis reservas, crear, cancelar y calendario.
- [ ] Documentar arquitectura, setup, decisiones técnicas y flujo de uso para desarrollo/compilación.
- [ ] Probar la app en las plataformas disponibles y ajustar errores encontrados.
- [ ] Dejar checklist final y marcar tareas completadas.
## Notas
- Priorizar Flutter vanilla y evitar dependencias innecesarias.
- Documentar ampliamente en código y en archivos Markdown.
- Usar la API autenticada recién implementada en FAN.
- Endpoints confirmados para la app: `/api/external/auth/*`, `/api/profile`, `/api/profile/change-password`, `/api/incubada`, `/api/config-general`, y los endpoints de reservas de salas/equipos para incubadas.
- Toolchain instalado y validado: Flutter 3.41.5, Dart 3.11.3, Java 17, Android SDK 36, Chrome para Web y Linux toolchain.
