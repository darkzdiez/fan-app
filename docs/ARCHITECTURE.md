# Arquitectura de FAN App

## Objetivo

Mantener una app Flutter bastante vanilla, con pocas dependencias y sin capas mágicas difíciles de seguir.

## Decisiones principales

### 1. Sin paquetes de estado externos

En vez de Provider, Riverpod o Bloc, la app usa:

- `ChangeNotifier`
- `InheritedNotifier`
- `AnimatedBuilder`
- `StatefulWidget`

Eso permite que cualquier dev Flutter pueda seguir el flujo sin tener que entender un framework adicional.

### 2. Un único cliente API

`lib/src/core/api_client.dart` concentra:

- headers comunes
- bearer token
- requests GET
- requests multipart POST
- parsing JSON
- transformación de errores 4xx/5xx a `ApiException`

### 3. Persistencia mínima

`shared_preferences` guarda la sesión serializada.

Se eligió por simplicidad y compatibilidad cross-platform. Si más adelante querés endurecer almacenamiento en mobile, se puede migrar a `flutter_secure_storage` sin romper el resto de la arquitectura.

### 4. Módulo genérico de reservas

Salas y equipos comparten mucha lógica, así que la app implementa una sola capa genérica basada en `BookableResourceType`.

Eso evita duplicar:

- tabs de listado / reservas / calendario
- cliente API
- parsing de DTOs
- formularios de reserva
- cancelación y rating

## Estructura

```text
lib/
├── main.dart
└── src/
    ├── app.dart
    ├── core/
    │   ├── api_client.dart
    │   ├── app_controller.dart
    │   ├── app_environment.dart
    │   ├── app_scope.dart
    │   ├── models.dart
    │   ├── session_storage.dart
    │   ├── utils.dart
    │   └── widgets.dart
    └── features/
        ├── auth/
        ├── profile/
        ├── organization/
        └── reservations/
```

## Flujo de autenticación

1. La app arranca y `AppController.bootstrap()` intenta restaurar una sesión persistida.
2. Si encuentra token, consulta `/api/external/auth/me`.
3. Si el token sigue válido, también trae `/api/config-general`.
4. Si falla, limpia sesión y vuelve al login.
5. En login, se autentica contra `/api/external/auth/login`.

## Flujo de reservas

### Salas

Para incubadas, la app trata las salas como reserva de bloque fijo:

- el usuario elige fecha
- consulta disponibilidad
- elige hora de inicio
- backend calcula el bloque según `reservation_interval_minutes`

### Equipos

Para equipos, la app permite `desde` / `hasta`:

- el usuario elige fecha
- consulta disponibilidad
- elige inicio y fin
- backend valida reglas y solapamientos

### QR desde el bottom bar

El tab QR del bottom bar no cambia de módulo: abre un flujo transversal que:

- se habilita con el permiso genérico `bookable-resources-qr-scan`,
- escanea con cámara cuando la plataforma lo soporta,
- permite pegar manualmente la URL o el UUID del QR como fallback,
- resuelve el recurso con `GET /api/bookable-resource/qr/{uuid}`,
- reutiliza el mismo diálogo de reserva usado por salas y equipos.

## Validaciones que se delegan al backend

Aunque la app hace algunas validaciones UX, la fuente de verdad sigue siendo la API:

- permisos
- organización efectiva
- solapamientos
- límites diarios / consecutivos
- cancelación de reservas pasadas
- rating solo para reservas finalizadas

## Comentarios de mantenimiento

- Las pantallas están comentadas en las secciones que concentran reglas de negocio.
- Los modelos se parsean a mano para evitar codegen y mantener el proyecto simple.
- Si en el futuro aparecen más módulos incubada, conviene seguir el mismo patrón `repository + screen + DTOs`.
