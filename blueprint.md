# ProsaVis Blueprint

## Visión General

ProsaVis es una aplicación móvil diseñada para conectar a usuarios con proveedores de servicios locales. La aplicación facilita la búsqueda, reserva y gestión de una amplia gama de servicios, desde reparaciones del hogar hasta clases particulares.

## Funcionalidades Implementadas

*   **Autenticación de Usuarios:**
    *   Inicio de sesión con correo electrónico y contraseña.
    *   Registro de nuevos usuarios.
*   **Gestión de Perfil:**
    *   Creación y edición de perfiles de usuario.
    *   Visualización de información de proveedores.
*   **Navegación y Búsqueda:**
    *   Página de inicio con categorías de servicios.
    *   Búsqueda avanzada con filtros.
    *   Visualización de detalles de servicios y proveedores.

## Plan de Desarrollo Actual

### Tarea: Implementar Inicio de Sesión con Google

**Objetivo:** Permitir a los usuarios registrarse e iniciar sesión en ProsaVis utilizando sus cuentas de Google, simplificando el proceso de autenticación y mejorando la experiencia del usuario.

**Pasos a Seguir:**

1.  **Configurar el Proyecto de Firebase:**
    *   Habilitar la autenticación de Google en la consola de Firebase.
    *   Asegurarse de que el archivo `firebase_options.dart` esté correctamente configurado.

2.  **Integrar el SDK de Autenticación de Google:**
    *   Añadir las dependencias `firebase_auth` y `google_sign_in` al archivo `pubspec.yaml`.
    *   Configurar las credenciales de cliente OAuth 2.0 para Android y iOS.

3.  **Actualizar la Lógica de Autenticación:**
    *   Crear un `AuthBloc` para gestionar el estado de la autenticación.
    *   Implementar el `SignInWithGoogleUseCase` para manejar el flujo de inicio de sesión con Google.
    *   Actualizar la interfaz de usuario para incluir un botón de "Iniciar Sesión con Google".

4.  **Gestionar el Estado del Usuario:**
    *   Crear el `UserEntity` para representar la información del usuario de manera consistente en toda la aplicación.
    *   Utilizar el `AuthRepository` para interactuar con Firebase y gestionar los datos del usuario.

5.  **Refinar la Experiencia de Usuario:**
    *   Diseñar una página de Onboarding atractiva que guíe a los nuevos usuarios.
    *   Añadir un `GradientBackground` y un `ProsavisLogo` para mantener la coherencia de la marca.
    *   Implementar un sistema de navegación fluido utilizando `go_router`.
