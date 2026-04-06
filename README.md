# FAN App

App Flutter multiplataforma orientada a incubadas de FAN.

La app consume la autenticación API externa recién implementada en FAN y expone los flujos principales que hoy usa una incubada en la versión web:

- inicio de sesión con token bearer
- perfil de usuario
- cambio de contraseña
- edición de datos de la incubada
- reservas de salas de reunión
- reservas de equipos de laboratorio
- calendario mensual de reservas

## Dependencias elegidas

La app se mantuvo deliberadamente simple.

Solo usa dependencias realmente necesarias:

- `http`: cliente HTTP liviano
- `shared_preferences`: persistencia básica de sesión/token
- `file_picker`: selección de archivos para logo y documentos de la incubada
- `flutter_localizations`: localización del SDK para date pickers y widgets en castellano

## Requisitos del entorno

Este entorno ya quedó preparado con:

- Flutter `3.41.5`
- Dart `3.11.3`
- Java `17`
- Android SDK `36`
- Chrome para Web

## Configuración de la API

La app espera la URL completa del backend con `/api` incluido.

Ejemplos:

```bash
flutter run -d chrome --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
flutter build web --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
flutter build apk --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
flutter build apk --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

### URL por defecto

Si no se pasa `FAN_API_BASE_URL`, la app usa:

```text
http://127.0.0.1:8000/api
```

La UI muestra un banner avisando cuando sigue usando esa URL por defecto.

## Cómo correr la app

### Web

En Chrome:

```bash
flutter run -d chrome --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

Como live preview en un servidor local:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

Después abrí `http://127.0.0.1:3000/`.

Si omitís `--dart-define=FAN_API_BASE_URL=...`, la app va a caer en `http://127.0.0.1:8000/api`, que solo sirve si también tenés un backend local levantado en ese puerto.

Si querés apuntar a otro backend, reemplazá el valor de `FAN_API_BASE_URL`.

### Android

```bash
flutter run -d android --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

> Si más adelante querés apuntar a un backend local desde un emulador Android, podés usar `http://10.0.2.2:8000/api`.

### Linux desktop

Aunque el objetivo principal es iOS/Android/Web, el entorno quedó listo también para Linux desktop:

```bash
flutter run -d linux --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

## Builds

### Web

```bash
flutter build web --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

### Android APK

```bash
flutter build apk --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

### iOS

La carpeta `ios/` ya está generada, pero la compilación final de iOS debe hacerse en macOS:

```bash
flutter build ios --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

## Funcionalidad incluida

### Perfil

- leer perfil actual desde `/api/profile`
- editar nombre, username y correo
- cambiar contraseña con `/api/profile/change-password`

### Incubada

- leer datos desde `/api/incubada`
- editar campos principales y vigencias
- subir logo y documentos por multipart

### Salas de reunión

- listado
- detalle
- auto-reserva
- mis reservas
- cancelación
- calificación
- calendario mensual

### Equipos de laboratorio

- listado
- detalle
- auto-reserva
- mis reservas
- cancelación
- calificación
- calendario mensual

## Documentación adicional

- `plan.md`: seguimiento de tareas
- `docs/ARCHITECTURE.md`: organización del código y decisiones
- `docs/API_INTEGRATION.md`: endpoints y contratos usados por la app

## Comandos útiles

Actualizar Flutter, revisar dependencias, actualizarlas y levantar el preview web:

```bash
flutter upgrade \
&& flutter pub outdated \
&& flutter pub upgrade --major-versions \
&& flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api
```

Actualizar Flutter, revisar dependencias, actualizarlas y generar APK release y debug:

```bash
flutter upgrade \
&& flutter pub outdated \
&& flutter pub upgrade --major-versions \
&& flutter build apk --release \
&& flutter build apk --debug
```