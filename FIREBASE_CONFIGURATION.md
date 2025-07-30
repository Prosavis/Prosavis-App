# 🔥 Configuración de Firebase para Prosavis

## Estado Actual
✅ **Layout del login corregido** - Se elimninó el overflow de 169 pixels  
✅ **Logo de color configurado** - Usando `logo-color.svg` correctamente  
✅ **Configuración base de Firebase** - Valores demo funcionales  

## Configuración Real de Firebase

### 1. Crear Proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto llamado `prosavis` o `prosavis-demo`
3. Habilita los siguientes servicios:
   - **Authentication** > Sign-in method > Google
   - **Cloud Firestore** > Crear base de datos
   - **Analytics** (opcional)

### 2. Configurar Google Sign-In

#### Para Web:
1. En Firebase Console > Project Settings > General
2. Añade una app Web con nombre "Prosavis Web"
3. Copia la configuración y reemplaza en `firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'TU_API_KEY_WEB',                    // Reemplazar
  appId: 'TU_APP_ID_WEB',                     // Reemplazar  
  messagingSenderId: 'TU_MESSAGING_SENDER_ID', // Reemplazar
  projectId: 'tu-proyecto-real',               // Reemplazar
  authDomain: 'tu-proyecto-real.firebaseapp.com',
  storageBucket: 'tu-proyecto-real.appspot.com',
  measurementId: 'TU_MEASUREMENT_ID',          // Reemplazar
);
```

#### Para Android:
1. Añade una app Android con package name: `com.prosavis.app`
2. Descarga `google-services.json`
3. Coloca el archivo en `android/app/google-services.json`
4. Reemplaza los valores en `firebase_options.dart`

#### Para iOS:
1. Añade una app iOS con Bundle ID: `com.prosavis.app`
2. Descarga `GoogleService-Info.plist`
3. Añade el archivo al proyecto iOS en Xcode
4. Reemplaza los valores en `firebase_options.dart`

### 3. Habilitar Google Sign-In

1. Ve a **Authentication** > **Sign-in method**
2. Habilita **Google**
3. Configura el email de soporte del proyecto
4. Para Web: añade el dominio autorizado

### 4. Configurar SHA-1 para Android (Desarrollo)

```bash
# Generar SHA-1 para debug
cd android
./gradlew signingReport

# Buscar la línea SHA1 para 'debug'
# Copiar y pegar en Firebase Console > Project Settings > Android App
```

### 5. Verificar Configuración

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la app
flutter run -d chrome  # Para web
flutter run            # Para móvil
```

## Valores Demo Actuales

Los valores actuales en `firebase_options.dart` son de demostración y **NO funcionarán** para Google Sign-In real. Son válidos para:

- ✅ Inicialización básica de Firebase
- ✅ Evitar errores de configuración null
- ✅ Modo desarrollo local
- ❌ Google Sign-In funcional
- ❌ Firestore real
- ❌ Producción

## Solución de Problemas

### Error: "FirebaseOptions cannot be null"
- ✅ **RESUELTO** - Se configuraron valores demo válidos

### Error: Google Sign-In falla
- ⚠️ **REQUIERE ACCIÓN** - Configurar proyecto Firebase real con las credenciales correctas

### Error: "No such project exists"
- ⚠️ **REQUIERE ACCIÓN** - Cambiar `projectId` en `firebase_options.dart` por tu proyecto real

## Próximos Pasos

1. **Inmediato**: La app funciona en modo demo con layout corregido
2. **Para producción**: Configurar proyecto Firebase real siguiendo esta guía
3. **Testing**: Google Sign-In funcionará solo con configuración real

## Soporte

Si necesitas ayuda configurando Firebase:
1. Revisa la [documentación oficial](https://firebase.flutter.dev/)
2. Usa `flutterfire configure` para generar automáticamente las opciones
3. Asegúrate de habilitar los servicios necesarios en Firebase Console