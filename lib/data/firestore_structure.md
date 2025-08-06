# 🔥 Estructura de Firestore para Prosavis App

## 📊 **Colecciones Principales**

Tu app usa **3 colecciones principales** en Firestore:

### 👥 **Colección: `users`**
Almacena información de usuarios registrados.

```json
/users/{userId}
{
  "id": "uuid-del-usuario",
  "name": "Juan Pérez",
  "email": "juan@example.com", 
  "photoUrl": "https://...jpg",
  "phoneNumber": "+57 300 123 4567",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z"
}
```

### 🛠️ **Colección: `services`**
Almacena servicios ofrecidos por proveedores.

```json
/services/{serviceId}
{
  "id": "uuid-del-servicio",
  "title": "Plomería Residencial",
  "description": "Servicio completo de plomería...",
  "category": "Hogar",
  "price": 50000.0,
  "priceType": "fixed", // "fixed", "hourly", "negotiable"
  "providerId": "uuid-del-proveedor",
  "providerName": "Juan Pérez",
  "providerPhotoUrl": "https://...jpg",
  "images": ["https://...jpg", "https://...jpg"],
  "tags": ["plomería", "tubería", "reparación"],
  "isActive": true,
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z",
  "rating": 4.5,
  "reviewCount": 23,
  "address": "Calle 123 # 45-67",
  "location": {
    "latitude": 4.6097,
    "longitude": -74.0817
  },
  "availabilityRadius": 10, // km
  "availableDays": ["lunes", "martes", "miércoles"],
  "timeRange": "09:00-17:00"
}
```

### ❤️ **Colección: `favorites`**
Almacena los servicios favoritos de cada usuario.

```json
/favorites/{favoriteId}
{
  "id": "uuid-del-favorito",
  "userId": "uuid-del-usuario",
  "serviceId": "uuid-del-servicio",
  "createdAt": "2024-01-01T10:00:00Z"
}
```

### 🌟 **Colección: `reviews`**
Almacena las reseñas y calificaciones de servicios.

```json
/reviews/{reviewId}
{
  "id": "uuid-de-la-reseña",
  "serviceId": "uuid-del-servicio",
  "userId": "uuid-del-usuario",
  "userName": "María García",
  "userPhotoUrl": "https://...jpg",
  "rating": 5,
  "comment": "Excelente servicio, muy recomendado",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z"
}
```

## 🔧 **Funciones Automáticas**

### ✅ **Creación Automática**
- Las colecciones se crean **automáticamente** cuando guardas el primer documento
- No necesitas crear nada manualmente en Firebase Console
- Tu app tiene toda la lógica para crear/leer/actualizar/eliminar datos

### 📱 **Casos de Uso**

1. **Registro de usuario nuevo**:
   ```dart
   FirestoreService().createOrUpdateUser(userEntity);
   ```
   → Crea documento en `/users/{userId}`

2. **Proveedor publica servicio**:
   ```dart
   FirestoreService().createService(serviceEntity);
   ```
   → Crea documento en `/services/{serviceId}`

3. **Buscar servicios**:
   ```dart
   FirestoreService().searchServices(category: "Hogar");
   ```
   → Lee documentos de `/services` con filtros

4. **Agregar servicio a favoritos**:
   ```dart
   FavoriteRepositoryImpl().addToFavorites(userId: "...", serviceId: "...");
   ```
   → Crea documento en `/favorites/{favoriteId}`

5. **Crear reseña**:
   ```dart
   ReviewRepositoryImpl().createReview(reviewEntity);
   ```
   → Crea documento en `/reviews/{reviewId}`

## 🔍 **Consultas Implementadas**

### **Usuarios**
- ✅ `getUserById(id)` - Usuario por ID
- ✅ `getUserByEmail(email)` - Usuario por email
- ✅ `getAllUsers()` - Todos los usuarios
- ✅ `createOrUpdateUser(user)` - Crear/actualizar
- ✅ `deleteUser(id)` - Eliminar usuario

### **Servicios**
- ✅ `getServiceById(id)` - Servicio por ID
- ✅ `getServicesByUserId(userId)` - Servicios de un proveedor
- ✅ `getAllServices()` - Todos los servicios
- ✅ `getAvailableServices()` - Servicios disponibles
- ✅ `searchServices(filtros)` - Búsqueda con filtros
- ✅ `createService(service)` - Crear servicio
- ✅ `updateService(service)` - Actualizar servicio
- ✅ `deleteService(id)` - Eliminar servicio
- ✅ `watchAllServices()` - Stream tiempo real
- ✅ `watchUserServices(userId)` - Stream de usuario

### **Favoritos**
- ✅ `addToFavorites(userId, serviceId)` - Agregar a favoritos
- ✅ `removeFromFavorites(userId, serviceId)` - Quitar de favoritos
- ✅ `isFavorite(userId, serviceId)` - Verificar si es favorito
- ✅ `getUserFavorites(userId)` - Favoritos de un usuario
- ✅ `getUserFavoriteServices(userId)` - Servicios favoritos con detalles
- ✅ `cleanupInvalidFavorites(userId)` - Limpiar favoritos inválidos

### **Reseñas**
- ✅ `createReview(review)` - Crear reseña
- ✅ `getServiceReviews(serviceId)` - Reseñas de un servicio
- ✅ `getUserReviews(userId)` - Reseñas de un usuario
- ✅ `updateReview(review)` - Actualizar reseña
- ✅ `deleteReview(reviewId)` - Eliminar reseña

## 🚨 **Importante**

### **NO Necesitas Crear Nada Manualmente**
- ❌ No crees colecciones en Firebase Console
- ❌ No agregues documentos manualmente
- ❌ No configures índices todavía

### **La App Se Encarga de Todo**
- ✅ Cuando un usuario se registre → se crea `/users/{id}`
- ✅ Cuando publique un servicio → se crea `/services/{id}`
- ✅ Cuando marque un favorito → se crea `/favorites/{id}`
- ✅ Cuando escriba una reseña → se crea `/reviews/{id}`
- ✅ Todas las consultas están implementadas
- ✅ La estructura se genera automáticamente

## 📋 **Próximos Pasos**

1. **Probar registro de usuario** → Verás datos en `/users`
2. **Crear un servicio** → Verás datos en `/services`
3. **Marcar favoritos** → Verás datos en `/favorites`
4. **Escribir reseñas** → Verás datos en `/reviews`
5. **Si hay consultas lentas** → Firestore sugerirá índices automáticamente

## 🔒 **Reglas de Seguridad (Opcional)**

Cuando tengas datos reales, puedes configurar reglas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios solo pueden leer/escribir sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Servicios: todos pueden leer, solo el proveedor puede escribir
    match /services/{serviceId} {
      allow read: if true;
      allow write: if request.auth != null && 
                   request.auth.uid == resource.data.providerId;
    }
    
    // Favoritos: solo el usuario puede gestionar sus favoritos
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null && 
                         request.auth.uid == resource.data.userId;
    }
    
    // Reseñas: todos pueden leer, solo el autor puede escribir/editar
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                            request.auth.uid == resource.data.userId;
    }
  }
}
```

¡Tu base de datos está lista para usar! 🚀