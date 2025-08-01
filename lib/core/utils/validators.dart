class Validators {
  // Validación de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    
    if (!value.contains('@')) {
      return 'El correo debe contener el símbolo @';
    }
    
    // Expresión regular más completa para email
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }
    
    return null;
  }

  // Validación de contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    if (value.length > 32) {
      return 'La contraseña no puede exceder 32 caracteres';
    }
    
    // Al menos una letra
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra';
    }
    
    return null;
  }

  // Validación de nombre
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }
    
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    
    if (value.length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }
    
    // Solo letras, espacios y algunos caracteres especiales
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo puede contener letras y espacios';
    }
    
    // No permitir solo espacios
    if (value.trim().isEmpty) {
      return 'El nombre no puede estar vacío';
    }
    
    return null;
  }

  // Validación de teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    
    // Remover espacios y caracteres especiales
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos';
    }
    
    if (cleanPhone.length > 15) {
      return 'El teléfono no puede exceder 15 dígitos';
    }
    
    return null;
  }

  // Validación de confirmación de contraseña
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  // Validación genérica para campos requeridos
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }
}