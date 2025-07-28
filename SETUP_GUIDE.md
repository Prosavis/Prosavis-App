# Guía de Configuración - ServicioConecta

## 🚀 Instalación de Flutter

### Windows

1. **Descargar Flutter:**
   - Ve a https://flutter.dev/docs/get-started/install/windows
   - Descarga el Flutter SDK
   - Extrae el archivo en `C:\flutter`

2. **Configurar PATH:**
   - Busca "Variables de entorno" en el menú de Windows
   - Edita las variables de entorno del sistema
   - Agrega `C:\flutter\bin` al PATH

3. **Verificar instalación:**
   ```powershell
   flutter doctor
   ```

### macOS

1. **Usar Homebrew:**
   ```bash
   brew install flutter
   ```

2. **O descargar manualmente:**
   - Descarga desde https://flutter.dev/docs/get-started/install/macos
   - Agrega al PATH en `~/.zshrc` o `~/.bash_profile`

### Linux

1. **Descargar Flutter:**
   ```bash
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
   tar xf flutter_linux_3.16.0-stable.tar.xz
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

## 🔥 Configuración de Firebase

### 1. Crear Proyecto en Firebase

1. Ve a https://console.firebase.google.com/
2. Crea un nuevo proyecto
3. Habilita Authentication y Firestore
4. Configura Google Sign-in en Authentication > Sign-in method

### 2. Configurar Aplicación

1. **Instalar FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configurar Firebase:**
   ```bash
   flutterfire configure
   ```
   - Selecciona tu proyecto
   - Elige las plataformas (Android, iOS, Web, etc.)
   - Esto creará `firebase_options.dart` con la configuración correcta

### 3. Configurar Google Sign-In

#### Android
1. Ve a Firebase Console > Project Settings > General
2. En "Your apps", selecciona la app Android
3. Descarga `google-services.json`
4. Copia el archivo a `android/app/google-services.json`

#### iOS
1. Descarga `GoogleService-Info.plist`
2. Agrega el archivo al proyecto iOS en Xcode

#### Web
1. Ve a Firebase Console > Project Settings > General
2. En "Your apps", selecciona la app Web
3. Copia la configuración y úsala en `firebase_options.dart`

## 📱 Ejecutar la Aplicación

### 1. Instalar Dependencias
```bash
flutter pub get
```

### 2. Ejecutar la App
```bash
# Para desarrollo (debug)
flutter run

# Para probar en dispositivo específico
flutter devices  # Ver dispositivos disponibles
flutter run -d <device_id>

# Para web
flutter run -d chrome
```

## 🛠️ Solución de Problemas Comunes

### Error: "flutter: command not found"
- Verificar que Flutter esté en el PATH
- Reiniciar la terminal/PowerShell
- Ejecutar `flutter doctor` para verificar

### Error de Firebase
1. Verificar que `firebase_options.dart` existe
2. Comprobar que las APIs están habilitadas en Firebase Console
3. Verificar que los archivos de configuración están en su lugar

### Error de Google Sign-In
1. Verificar SHA-1 fingerprint en Firebase Console
2. Para debug en Android:
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
   ```
3. Agregar el fingerprint en Firebase Console > Project Settings > SHA certificate fingerprints

### Error de dependencias
```bash
flutter clean
flutter pub get
```

## 📁 Estructura del Proyecto

```
lib/
├── core/                 # Configuración central
│   ├── constants/       # Constantes de la app
│   ├── themes/         # Temas y estilos
│   ├── injection/      # Inyección de dependencias
│   └── usecases/       # Casos de uso base
├── data/                # Capa de datos
│   ├── models/         # Modelos de datos
│   ├── repositories/   # Implementaciones de repositorios
│   └── services/       # Servicios (Firebase, etc.)
├── domain/              # Lógica de negocio
│   ├── entities/       # Entidades del dominio
│   ├── repositories/   # Contratos de repositorios
│   └── usecases/       # Casos de uso
└── presentation/        # Capa de presentación
    ├── blocs/          # BLoC para gestión de estado
    ├── pages/          # Páginas de la aplicación
    └── widgets/        # Widgets reutilizables
```

## 🔧 Configuración de Desarrollo

### VS Code Extensions Recomendadas
- Flutter
- Dart
- Awesome Flutter Snippets
- Bracket Pair Colorizer
- GitLens

### Android Studio Plugins
- Flutter
- Dart

## 📋 Checklist de Configuración

- [ ] Flutter instalado y en PATH
- [ ] `flutter doctor` sin errores críticos
- [ ] Proyecto Firebase creado
- [ ] FlutterFire CLI instalado
- [ ] `firebase_options.dart` generado
- [ ] Google Sign-in configurado
- [ ] Dependencias instaladas (`flutter pub get`)
- [ ] App ejecutándose sin errores

## 🆘 Obtener Ayuda

Si encuentras problemas:

1. Ejecuta `flutter doctor -v` para diagnóstico completo
2. Revisa los logs con `flutter logs`
3. Busca en [Flutter Documentation](https://flutter.dev/docs)
4. Consulta [Firebase Documentation](https://firebase.google.com/docs)

---

¡Listo! Tu aplicación ServicioConecta debería estar funcionando correctamente. 🎉 