# Guía de Conectividad del Emulador Android

## 🚨 Problemas Comunes de Conectividad

### Errores Típicos que Verás:
- `Failed host lookup: 'fonts.gstatic.com'`
- `Unable to resolve host "firestore.googleapis.com"`
- `No address associated with hostname`

### ¿Por qué Ocurre?
Los emuladores de Android tienen limitaciones de red que pueden causar problemas de conectividad DNS.

## 🔧 Soluciones Implementadas

### 1. **Sistema de Fuentes con Fallback**
- ✅ **FontManager**: Maneja automáticamente el fallback de Google Fonts a fuentes locales
- ✅ **Fuente Local**: 'Archivo' configurada como fallback principal
- ✅ **Sistema de Fuentes**: Roboto, SF Pro, Segoe UI como fallbacks adicionales

### 2. **Configuración de Firestore Offline**
- ✅ **Persistencia Habilitada**: Los datos se guardan localmente
- ✅ **Cache Ilimitado**: Mejor experiencia sin conectividad
- ✅ **Manejo Gracioso**: Errores de red no bloquean la aplicación

### 3. **Configuración de Red Robusta**
- ✅ **Timeouts Permisivos**: Para emuladores lentos
- ✅ **Reintentos Automáticos**: Firebase maneja reintentos internamente
- ✅ **Modo Offline Primero**: La app funciona sin internet

## 🛠️ Soluciones Adicionales para el Emulador

### Opción 1: Configurar DNS del Emulador
```bash
# En Android Studio, editar el emulador:
# Settings > Advanced > DNS Settings
Primary DNS: 8.8.8.8
Secondary DNS: 8.8.4.4
```

### Opción 2: Usar Emulador con Google Play Services
```bash
# Crear AVD con:
- Target: Google APIs (no AOSP)
- System Image: Con Google Play Store
```

### Opción 3: Cold Boot del Emulador
```bash
# En Android Studio:
# AVD Manager > Actions > Cold Boot Now
```

### Opción 4: Configurar Proxy (Si usas proxy corporativo)
```bash
# En Emulator Settings:
# Settings > Proxy > Manual proxy configuration
```

## 📱 Verificar Funcionamiento

### Los errores de red NO afectan:
- ✅ **Navegación** de la aplicación
- ✅ **UI/UX** general  
- ✅ **Funcionalidad offline** de Firestore
- ✅ **Fuentes locales** como fallback

### Funcionalidades que pueden verse limitadas sin internet:
- ⚠️ **Descarga de Google Fonts** (usa fallbacks automáticamente)
- ⚠️ **Sincronización en tiempo real** con Firestore (funciona cuando se restaure la conectividad)
- ⚠️ **Autenticación con Google** (puede requerir conectividad)

## 🔍 Monitoring y Diagnóstico

### Logs Útiles para Diagnóstico:
```dart
// Estos logs indican funcionamiento normal:
I/flutter: ✅ Google Fonts precargado exitosamente
I/flutter: ✅ Firestore configurado con persistencia offline
I/flutter: ✅ FontManager manejó la precarga con fallbacks

// Estos logs son normales en emuladores sin conectividad:
W/Firestore: Could not reach Cloud Firestore backend
I/flutter: ⚠️ Google Fonts no disponible, usando fallback local
```

## 🎯 Recomendaciones

### Para Desarrollo:
1. **Ignora los warnings de conectividad** - son normales en emuladores
2. **Verifica que la UI se vea correcta** - las fuentes locales deben funcionar
3. **Prueba funcionalidad offline** - Firestore debe persistir datos localmente
4. **Usa dispositivo real ocasionalmente** - para probar conectividad completa

### Para Testing:
1. **Prueba sin internet** - la app debe ser funcional
2. **Prueba con internet limitado** - debe manejar timeouts graciosamente  
3. **Prueba reconexión** - debe sincronizar al restaurar conectividad

## ✅ Cambios Realizados para Resolver Problemas

1. **FontManager**: Sistema robusto de fallback de fuentes
2. **Firestore Offline**: Persistencia habilitada por defecto
3. **Error Handling**: Manejo gracioso de errores de red
4. **Timeouts Configurados**: Para emuladores lentos
5. **Logging Mejorado**: Para diagnóstico más claro

La aplicación ahora debe funcionar correctamente incluso con los errores de conectividad mostrados en los logs.
