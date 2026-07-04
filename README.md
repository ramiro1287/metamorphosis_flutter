# Metamorphosis Gym — Flutter Client

Aplicación móvil para la gestión del gimnasio **Metamorphosis Gym** (Argentina), desarrollada en Flutter. Permite a administradores y alumnos gestionar pagos, planes de entrenamiento, notificaciones y más desde sus dispositivos Android e iOS.

## Funcionalidades principales

### Alumnos
- Consulta de pagos y estado de cuenta
- Visualización de planes de entrenamiento con detalle por día y ejercicio
- Pago online mediante MercadoPago
- Gestión de perfil (datos personales, dirección, contraseña)
- Centro de notificaciones

### Administradores / Coaches
- Gestión de usuarios (alta, edición, búsqueda)
- Gestión de pagos (listado paginado, edición, estadísticas)
- Gestión de planes de entrenamiento personalizados y plantillas reutilizables
- Asignación de planes a alumnos
- Gestión de grupos familiares
- Envío de comunicados/anuncios a alumnos
- Estadísticas de ingresos

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Dart ^3.12.2) |
| Estado global | Provider ^6.1.2 |
| Navegación | go_router ^14.8.1 |
| HTTP | Dio ^5.8.0 (con interceptor de refresh token JWT) |
| Almacenamiento local | shared_preferences ^2.3.3 |
| Imágenes | image_picker ^1.1.2 |
| Links externos | url_launcher ^6.3.1 |

## Backend

El backend es una API REST desarrollada en **Django + Django REST Framework**, desplegada en Railway.  
URL de producción: `https://metamorphosisgym.up.railway.app`

Autenticación mediante **JWT** (access token 3 min / refresh token 24 h).

## Configuración del entorno

El archivo `lib/constants/environment.dart` contiene la URL base del servidor:

```dart
// Producción
const String baseServerUrl = 'https://metamorphosisgym.up.railway.app';

// Emulador Android
// const String baseServerUrl = 'http://10.0.2.2:8000';

// Simulador iOS / desktop
// const String baseServerUrl = 'http://127.0.0.1:8000';
```

## Instalación

```bash
flutter pub get
flutter run
```
