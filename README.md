# ServicioConecta 🤝

Una aplicación móvil moderna que conecta prestadores de servicios con clientes, brindando una plataforma segura y confiable para encontrar servicios de calidad.

## ✨ Características

- **Autenticación con Google**: Inicio de sesión rápido y seguro
- **Interfaz moderna**: Diseño atractivo con animaciones suaves
- **Marketplace de servicios**: Encuentra desde plomería hasta tutoría
- **Arquitectura escalable**: Clean Architecture con BLoC pattern
- **Firebase Backend**: Base de datos en tiempo real y autenticación
- **Categorías diversas**: 10+ categorías de servicios disponibles

## 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework multiplataforma
- **Firebase**: Backend como servicio
- **BLoC**: Gestión de estado
- **Get It**: Inyección de dependencias
- **Google Fonts**: Tipografías modernas
- **Material Symbols**: Iconografía moderna

## 🏗️ Arquitectura

El proyecto sigue los principios de Clean Architecture:

```
lib/
├── core/                    # Configuraciones y utilidades
│   ├── constants/          # Constantes de la aplicación
│   ├── themes/             # Temas y colores
│   ├── injection/          # Inyección de dependencias
│   └── usecases/           # Casos de uso base
├── data/                   # Capa de datos
│   ├── models/             # Modelos de datos
│   ├── repositories/       # Implementaciones de repositorios
│   └── services/           # Servicios externos (Firebase)
├── domain/                 # Lógica de negocio
│   ├── entities/           # Entidades del dominio
│   ├── repositories/       # Contratos de repositorios
│   └── usecases/           # Casos de uso
└── presentation/           # Capa de presentación
    ├── blocs/              # BLoCs para gestión de estado
    ├── pages/              # Pantallas de la aplicación
    └── widgets/            # Widgets reutilizables
```

## 🚀 Configuración Inicial

### Prerrequisitos

1. **Flutter SDK** (versión 3.8.0+)
   ```bash
   # Descargar desde: https://flutter.dev/docs/get-started/install
   ```

2. **Dart SDK** (incluido con Flutter)

3. **Android Studio** o **VS Code** con extensiones de Flutter

4. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

### Configuración del Proyecto

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/myapp.git
   cd myapp
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   
   a. Crear un proyecto en [Firebase Console](https://console.firebase.google.com/)
   
   b. Habilitar servicios:
   - Authentication (Google Sign-In)
   - Cloud Firestore
   - Firebase Analytics (opcional)
   
   c. Descargar `google-services.json` para Android y `GoogleService-Info.plist` para iOS

4. **Configurar variables de entorno**
   
   Editar el archivo `.env` con tus credenciales:
   ```env
   FIREBASE_PROJECT_ID=tu-proyecto-firebase
   FIREBASE_API_KEY=tu-api-key
   FIREBASE_APP_ID=tu-app-id
   FIREBASE_MESSAGING_SENDER_ID=tu-sender-id
   GOOGLE_CLIENT_ID=tu-google-client-id
   ENV=development
   ```

5. **Configurar autenticación de Google**
   
   En Firebase Console > Authentication > Sign-in method:
   - Habilitar Google Sign-In
   - Configurar SHA-1 para Android
   - Configurar Bundle ID para iOS

## 📱 Ejecutar la Aplicación

```bash
# Verificar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release
```

## 🏗️ Compilar para Producción

### Android
```bash
flutter build apk --release
# o para App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔧 Comandos Útiles

```bash
# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Limpiar build
flutter clean

# Actualizar dependencias
flutter pub upgrade
```

## 📋 Funcionalidades Principales

### 🔐 Autenticación
- Inicio de sesión con Google
- Gestión automática de sesiones
- Estados de autenticación en tiempo real

### 🏠 Pantalla Principal
- Búsqueda de servicios
- Categorías de servicios
- Servicios destacados
- Servicios cercanos

### 🎨 Interfaz de Usuario
- Tema moderno con Material 3
- Animaciones suaves
- Iconos llamativos
- Gradientes atractivos

### 📱 Navegación
- Onboarding para nuevos usuarios
- Navegación fluida entre pantallas
- Bottom navigation bar

## 🚧 Estado del Proyecto

✅ **Completado:**
- Arquitectura base
- Autenticación con Google
- Pantallas principales
- Configuración de Firebase
- Widgets reutilizables

🔄 **En Desarrollo:**
- Funcionalidad de servicios
- Chat en tiempo real
- Sistema de reservas
- Pagos integrados

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Soporte

Si tienes preguntas o problemas:

1. Revisa la documentación
2. Busca en Issues existentes
3. Crea un nuevo Issue con detalles

## 🎯 Roadmap

- [ ] Sistema de calificaciones
- [ ] Notificaciones push
- [ ] Mapa de servicios
- [ ] Modo oscuro
- [ ] Soporte multi-idioma
- [ ] Pagos con Stripe
- [ ] Sistema de referidos

---

**¡Gracias por usar Prosavis!** 🚀

Desarrollado con ❤️ usando Flutter y Firebase.
