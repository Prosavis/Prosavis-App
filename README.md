# Prosavis 🤝

Plataforma móvil para conectar prestadores de servicios con clientes. Enfocada en seguridad, rendimiento y una experiencia moderna.

## ✨ Características Clave

- **Autenticación completa**: Google, Email/Contraseña, Teléfono (SMS), Anónimo y MFA (multi-factor). Ver guía MFA en `presentation/pages/auth/mfa_documentation.md`.
- **Marketplace**: Publicación, edición y eliminación de servicios; favoritos; reseñas y calificaciones.
- **Búsqueda avanzada**: Por categoría, rango de precio y filtros; soporte de geolocalización para servicios cercanos.
- **Arquitectura escalable**: Clean Architecture con BLoC y DI (`get_it`).
- **Firebase**: Auth, Cloud Firestore, Storage y configuración con FlutterFire.
- **UI moderna**: Material 3, animaciones, imágenes SVG, tipografías Google Fonts.

## 🛠️ Tecnologías

- **Flutter** (Android, iOS, Web)
- **Dart** (>= 3.2.3)
- **BLoC** (`flutter_bloc`), **DI** (`get_it`), **Routing** (`go_router`)
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`
- **Geolocalización**: `geolocator`, `geocoding`
- **UI/UX**: `google_fonts`, `material_symbols_icons`, `animations`, `shimmer`, `flutter_svg`, `lottie`

Consulta versiones exactas en `pubspec.yaml`.

## 🏗️ Arquitectura

El proyecto sigue Clean Architecture con separación por capas y BLoC por feature.

```
lib/
├── core/                    # Configuración, temas, DI, utilidades
├── data/                    # Models, repositorios (impl), servicios (Firebase)
├── domain/                  # Entidades, contratos de repos y casos de uso
└── presentation/            # BLoCs, páginas y widgets reutilizables
```

Referencias:
- Firestore: `lib/data/services/firestore_service.dart`
- Auth & MFA: `lib/data/services/firebase_service.dart`
- Repositorios: `lib/data/repositories/*`
- Estructura DB: `lib/data/firestore_structure.md`

## 🚀 Configuración Inicial

### Prerrequisitos

- Flutter 3.19+ (para compatibilidad con Dart >= 3.2.3)
- Android Studio o VS Code con extensión Flutter
- Firebase CLI instalado

```bash
npm install -g firebase-tools
```

### 1) Clonar e instalar dependencias

```bash
git clone https://github.com/tu-usuario/prosavis-app.git
cd prosavis-app
flutter pub get
```

### 2) Configurar Firebase con FlutterFire

Este proyecto incluye `firebase_options.dart`, pero debes regenerarlo para tu proyecto:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project <tu-project-id>
```

Esto creará/actualizará `firebase_options.dart` con tus credenciales para Android, iOS y Web.

Recomendado en Firebase Console:
- Habilitar proveedores: Google, Email/Contraseña y Teléfono (para MFA/SMS)
- Cloud Firestore y Storage
- Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) si corresponde

Para Google Sign-In en Android, registra SHA-1/SHA-256; en iOS, configura tu Bundle ID.

### 3) Variables de entorno (opcional)

Puedes usar `.env` con `flutter_dotenv` para valores adicionales (no secretos de Firebase):

```env
ENV=development
FEATURE_FLAGS=
```

### 4) Lints y calidad de código

Este repo incluye `analysis_options.yaml` con `flutter_lints`. Ejecuta:

```bash
flutter analyze
dart fix --apply
```

## 📱 Ejecutar la aplicación

```bash
flutter devices
flutter run            # debug
flutter run --release  # release
```

## 🏗️ Compilar para producción

- Android APK: `flutter build apk --release`
- Android App Bundle: `flutter build appbundle --release`
- iOS: `flutter build ios --release`

## 🔒 Autenticación soportada

- Google (`google_sign_in`) con Firebase Auth
- Email/Contraseña (registro, login, recuperación de contraseña)
- Teléfono (SMS) y verificación de código
- MFA: inscripción y resolución de segundo factor vía SMS
- Sesiones y stream de estado de usuario en tiempo real

Ver pantallas en `presentation/pages/auth/*` y la documentación MFA.

## 🔥 Base de datos y datos

- Cloud Firestore con colecciones: `users`, `services`, `favorites` y subcolección `reviews` bajo `services/{id}`.
- Operaciones implementadas: creación/edición/eliminación de servicios, favoritos, reseñas, búsqueda con filtros, streams en tiempo real.
- Consulta ejemplos y reglas en `lib/data/firestore_structure.md`.

## 🧭 Navegación y pantallas

- Splash, Login, Verificación de teléfono, Olvidé mi contraseña
- Home, Búsqueda, Categorías, Notificaciones, Perfil
- Crear/Editar/Detalle de Servicio, Mis Servicios
- Favoritos y reseñas (crear, listar, estadísticas)

Router: `go_router` definido en `lib/main.dart`.

## 🧪 Desarrollo y utilidades

```bash
flutter analyze         # estática de código
flutter test            # tests
flutter clean           # limpiar build
flutter pub upgrade     # actualizar dependencias
```

Emuladores Firebase (opcional): configura puertos en `AppConfig` si deseas usar Emulator Suite en desarrollo.

## 🚧 Estado del proyecto

- Completado: arquitectura base, Auth (Google/Email/Teléfono/MFA), servicios, favoritos, reseñas, theming, navegación, assets.
- En progreso: chat en tiempo real, sistema de reservas, pagos integrados, notificaciones push, mapa de servicios, modo oscuro avanzado y multi-idioma.

## 🤝 Contribuir

1) Fork del repositorio
2) Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3) Commit: `git commit -m "feat: agrega <detalle>"`
4) Push: `git push origin feature/nueva-funcionalidad`
5) Abre un Pull Request

## 📄 Licencia

MIT. Ver `LICENSE`.

---

Hecho con ❤️ en Flutter y Firebase.
