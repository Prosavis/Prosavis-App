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

  // Validación de teléfono colombiano (10 dígitos)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    
    // Remover espacios y caracteres especiales
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length != 10) {
      return 'Ingresa un número válido de 10 dígitos';
    }
    
    // Validar que empiece con 3 (celulares colombianos)
    if (!cleanPhone.startsWith('3')) {
      return 'El número debe ser un celular (empezar con 3)';
    }
    
    return null;
  }

  // Formatear número colombiano para Firebase (+57)
  static String formatColombianPhone(String phoneNumber) {
    // Remover espacios y caracteres especiales
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Agregar +57 si no lo tiene
    if (cleanPhone.length == 10 && cleanPhone.startsWith('3')) {
      return '+57$cleanPhone';
    }
    
    return phoneNumber; // Retornar original si no cumple formato
  }

  // Extraer solo el número sin indicativo para almacenar
  static String extractColombianPhoneNumber(String phoneNumber) {
    // Remover espacios y caracteres especiales
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si ya es un número de 10 dígitos válido, retornarlo
    if (cleanPhone.length == 10 && cleanPhone.startsWith('3')) {
      return cleanPhone;
    }
    
    // Si tiene 12 dígitos y empieza con 57, extraer los últimos 10
    if (cleanPhone.length == 12 && cleanPhone.startsWith('57')) {
      final extractedNumber = cleanPhone.substring(2);
      if (extractedNumber.startsWith('3')) {
        return extractedNumber;
      }
    }
    
    // Si tiene +57 al inicio, extraer el número
    if (phoneNumber.startsWith('+57')) {
      final extractedNumber = phoneNumber.substring(3).replaceAll(RegExp(r'[^\d]'), '');
      if (extractedNumber.length == 10 && extractedNumber.startsWith('3')) {
        return extractedNumber;
      }
    }
    
    return phoneNumber; // Retornar original si no se puede procesar
  }

  // Formatear número completo para WhatsApp (con +57)
  static String formatForWhatsApp(String phoneNumber) {
    final cleanNumber = extractColombianPhoneNumber(phoneNumber);
    if (cleanNumber.length == 10 && cleanNumber.startsWith('3')) {
      return '57$cleanNumber'; // WhatsApp no necesita el +
    }
    return phoneNumber;
  }

  // Formatear número para mostrar en UI (con espacios)
  static String formatPhoneForDisplay(String phoneNumber) {
    // Remover espacios y caracteres especiales
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length == 10) {
      // Formato: 300 123 4567
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    
    return phoneNumber;
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