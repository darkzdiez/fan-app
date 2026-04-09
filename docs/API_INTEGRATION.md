# Integración API usada por FAN App

## Auth externa

Ambiente validado durante la implementación:

- `https://alfonzo-work.osole.com.ar:8448/api`

### `POST /api/external/auth/login`

Request:

- `username`
- `password`
- `device_name`

Response usada:

- `access_token`
- `user.*`

### `GET /api/external/auth/me`

Usada para restaurar la sesión al abrir la app.

### `POST /api/external/auth/logout`

Revoca el token actual.

## Perfil

### `GET /api/profile`

Response:

- `name`
- `username`
- `email`

### `POST /api/profile`

Request:

- `name`
- `username`
- `email`

### `POST /api/profile/change-password`

Request:

- `password`
- `password_confirmation`

## Incubada

### `GET /api/incubada`

Campos consumidos:

- `uuid`
- `name`
- `registration_date`
- `incubator`
- `contact_person`
- `phone`
- `email`
- `alarm_code`
- `status`
- `logo_url`
- `equipment_consent_url`
- `contract_url`
- `art_policy_url`
- `art_valid_from`
- `art_valid_to`
- `coverage_certificate_url`
- `coverage_valid_from`
- `coverage_valid_to`
- `has_non_repetition_clause`

### `POST /api/incubada`

Request multipart:

- `name`
- `registration_date`
- `incubator`
- `contact_person`
- `phone`
- `email`
- `alarm_code`
- `status`
- `art_valid_from`
- `art_valid_to`
- `coverage_valid_from`
- `coverage_valid_to`
- `has_non_repetition_clause`
- `logo` (file opcional)
- `equipment_consent` (file opcional)
- `contract` (file opcional)
- `art_policy` (file opcional)
- `coverage_certificate` (file opcional)

## Configuración general

### `GET /api/config-general`

Usada para reservas:

- `reservation_interval_minutes`
- `reservation_start_time`
- `reservation_end_time`
- `meeting_room_max_hours_per_day`
- `meeting_room_max_consecutive_hours`

## Salas de reunión

### Recursos

- `POST /api/meeting-room/`
- `GET /api/meeting-room/{id}`
- `GET /api/bookable-resource/qr/{uuid}`

### Reservas

- `POST /api/meeting-room-reservation/my-reservations`
- `POST /api/meeting-room-reservation/availability`
- `POST /api/meeting-room-reservation/self-reservation`
- `POST /api/meeting-room-reservation/cancel/{id}`
- `POST /api/meeting-room-reservation/rate/{id}`
- `POST /api/meeting-room-reservation/calendar`

## Equipos de laboratorio

### Recursos

- `POST /api/lab-equipment/`
- `GET /api/lab-equipment/{id}`
- `GET /api/bookable-resource/qr/{uuid}`

### Reservas

- `POST /api/lab-equipment-reservation/my-reservations`
- `POST /api/lab-equipment-reservation/availability`
- `POST /api/lab-equipment-reservation/self-reservation`
- `POST /api/lab-equipment-reservation/cancel/{id}`
- `POST /api/lab-equipment-reservation/rate/{id}`
- `POST /api/lab-equipment-reservation/calendar`

## Observaciones prácticas

- Todas las requests autenticadas mandan `Authorization: Bearer {token}`.
- Los POST salen en multipart/form-data para mantener consistencia con el backend actual.
- La app está pensada para incubadas, así que no expone flujos administrativos completos.
- El flujo QR extrae el UUID desde el valor escaneado y después resuelve el recurso usando el backend actual, sin depender del host embebido en el código QR.
- El acceso al escáner de la app se controla con el permiso genérico `bookable-resources-qr-scan`, separado de los permisos de ver QR en el backoffice.
