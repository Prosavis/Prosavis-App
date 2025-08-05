# Documentación de Geolocalización - Prosavis

## 🌍 Sistema de Ubicación GPS Real

Este sistema utiliza **geolocalización real** para obtener la ubicación actual del usuario y convertirla en direcciones legibles.

### 🔧 Tecnologías Utilizadas

- **`geolocator`**: Para obtener coordenadas GPS precisas
- **`geocoding`**: Para convertir coordenadas a direcciones legibles
- **Permisos nativos**: Manejo completo de permisos de ubicación

### 📋 Funcionalidades Implementadas

#### 1. **Obtención de Ubicación GPS** (`getCurrentUserLocation`)
- Verifica permisos automáticamente
- Obtiene coordenadas con alta precisión
- Maneja errores y estados de carga
- Retorna: `{latitude: double, longitude: double}`

#### 2. **Conversión a Dirección** (`getCurrentAddress`)
- Convierte coordenadas GPS a dirección legible
- Formato colombiano optimizado: `Carrera 7 #32-16, Bogotá, Cundinamarca, Colombia`
- Manejo robusto de errores de red

#### 3. **Gestión de Permisos** (`_handleLocationPermission`)
- Verificación automática de servicios GPS
- Solicitud de permisos si es necesario
- Detección de permisos denegados permanentemente

#### 4. **Información Completa** (`getCurrentLocationDetails`)
- Coordenadas + dirección + metadatos
- Precisión, altitud, velocidad, etc.
- Timestamp de la ubicación

### 🎯 Integración en UI

#### Botón GPS
```dart
ElevatedButton.icon(
  onPressed: _getCurrentLocation,
  icon: Icon(Symbols.my_location),
  label: Text('GPS'),
)
```

#### Manejo de Estados
- **🔍 Cargando**: Indicador visual con progreso
- **📍 Éxito**: Dirección obtenida y campo actualizado
- **❌ Error**: Mensajes específicos + botones de configuración

### 🔒 Permisos Requeridos (Android)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 🚀 Casos de Uso

1. **Creación de Servicios**: Auto-completar dirección del proveedor
2. **Edición de Servicios**: Actualizar ubicación actual
3. **Cálculo de Distancias**: Entre usuario y servicios cercanos

### 🔄 Flujo de Funcionamiento

1. Usuario presiona botón GPS
2. Sistema verifica permisos
3. Si no tiene permisos → Solicita al usuario
4. Obtiene coordenadas GPS con alta precisión
5. Convierte coordenadas a dirección legible
6. Actualiza campo de dirección automáticamente

### ⚠️ Manejo de Errores

- **Permisos denegados**: Botón para abrir configuración de app
- **GPS deshabilitado**: Botón para abrir configuración de ubicación
- **Sin conexión**: Mensaje informativo
- **Timeout**: Reintentar automáticamente

### 🎯 Precisión

- **LocationAccuracy.high**: Precisión máxima
- **distanceFilter: 10m**: Filtro de distancia para optimizar batería
- **Timeout personalizable**: Para evitar esperas infinitas
