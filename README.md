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
- `mobile_scanner`: escaneo de QR con cámara y soporte de ingreso manual
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
flutter run -d chrome --dart-define=FAN_API_BASE_URL=https://alfonzo-work.osole.com.ar:8448/api --release
flutter run -d chrome --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
flutter build web --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api --release
flutter build apk --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api --release
flutter build ios --release --no-codesign --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
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
flutter run -d chrome --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

Como live preview en un servidor local:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

Después abrí `http://127.0.0.1:3000/`.

Si omitís `--dart-define=FAN_API_BASE_URL=...`, la app va a caer en `http://127.0.0.1:8000/api`, que solo sirve si también tenés un backend local levantado en ese puerto.

Si querés apuntar a otro backend, reemplazá el valor de `FAN_API_BASE_URL`.

### Android

```bash
flutter run -d android --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

### iOS

```bash
flutter run -d ios --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

> Si más adelante querés apuntar a un backend local desde un emulador Android, podés usar `http://10.0.2.2:8000/api`.

### Linux desktop

Aunque el objetivo principal es iOS/Android/Web, el entorno quedó listo también para Linux desktop:

```bash
flutter run -d linux --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

## Builds

### Web

```bash
flutter build web --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

Salida generada: `build/web/`

Notas de publicación:

- no abras `build/web/index.html` con `file://`; el build web de Flutter debe servirse por HTTP/HTTPS
- para probarlo localmente, podés servirlo así: `python3 -m http.server 8000 -d build/web`
- al publicarlo, subí **todo el contenido** de `build/web/`, no solo `index.html`
- si lo vas a publicar dentro de una subruta (por ejemplo `/fan/`), generá el build con `--base-href /fan/`

### Android APK

```bash
flutter build apk --release --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

Salidas generadas:

- release: `build/app/outputs/flutter-apk/app-release.apk`
- debug: `build/app/outputs/flutter-apk/app-debug.apk`

### iOS

La carpeta `ios/` ya está generada y la compilación final debe hacerse en macOS. En este entorno quedó validado el build sin firma:

```bash
flutter build ios --release --no-codesign --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

Salida generada:

- device build sin firma: `build/ios/iphoneos/Runner.app`

Tanto el build `--release` como `--debug` sin firma dejan el bundle en esa misma ruta, así que el último build ejecutado sobrescribe el anterior.

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
- reserva por QR desde el bottom bar
- auto-reserva
- mis reservas
- cancelación
- calificación
- calendario mensual

### Equipos de laboratorio

- listado
- detalle
- reserva por QR desde el bottom bar
- auto-reserva
- mis reservas
- cancelación
- calificación
- calendario mensual

## Permisos relevantes

- el tab QR del bottom bar y el flujo de escaneo sólo se habilitan si el usuario autenticado tiene el permiso `bookable-resources-qr-scan`
- ese permiso es independiente de los permisos para ver QR dentro del backoffice web de FAN

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
&& flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

```bash
flutter upgrade \
&& flutter pub outdated \
&& flutter pub upgrade --major-versions \
&& flutter run -d chrome --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api
```

Actualizar Flutter, revisar dependencias, actualizarlas y generar APK release y debug:

```bash
flutter upgrade \
&& flutter pub outdated \
&& flutter pub upgrade --major-versions \
&& flutter build apk --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api --release \
&& flutter build apk --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api --debug
```

Actualizar Flutter, revisar dependencias, actualizarlas y generar build iOS release y debug sin firma:

```bash
flutter upgrade \
&& flutter pub outdated \
&& flutter pub upgrade --major-versions \
&& flutter build ios --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api --release --no-codesign \
&& flutter build ios --dart-define=FAN_API_BASE_URL=https://fan-test.osole.com.ar/api --debug --no-codesign
```
