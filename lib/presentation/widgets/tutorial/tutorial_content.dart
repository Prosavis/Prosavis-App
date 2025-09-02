import 'package:material_symbols_icons/symbols.dart';
import 'tutorial_overlay.dart';

/// Contenido del tutorial para cada paso del wizard de creación de servicios
class TutorialContent {
  
  /// Tutorial para el paso 1: Categoría
  static const TutorialStep categoryStep = TutorialStep(
    title: '🎯 Selecciona tu categoría',
    description: 'Aquí debes elegir la categoría que mejor describe tu servicio. Esto ayudará a los clientes a encontrarte más fácilmente.',
    tips: [
      'Elige la categoría más específica posible',
      'Los clientes buscan por categorías',
      'Una buena categoría aumenta tu visibilidad',
    ],
    icon: Symbols.category,
  );

  /// Tutorial para el paso 2: Información básica
  static const TutorialStep basicInfoStep = TutorialStep(
    title: '📝 Información básica',
    description: 'Aquí escribes el título y descripción de tu servicio. Un buen título y descripción atraen más clientes.',
    tips: [
      'Usa un título claro y descriptivo',
      'La descripción debe explicar qué incluye tu servicio',
      'Menciona tu experiencia y ventajas',
      'Mínimo 20 caracteres en la descripción',
    ],
    icon: Symbols.edit_note,
  );

  /// Tutorial para el paso 3: Precio
  static const TutorialStep pricingStep = TutorialStep(
    title: '💰 Define tu precio',
    description: 'Establece cómo vas a cobrar tu servicio. Puedes poner un precio fijo, por día, o negociable.',
    tips: [
      'Investiga precios de la competencia',
      'Considera tus costos y tiempo',
      'El precio negociable atrae más consultas',
      'Los precios claros generan más confianza',
    ],
    icon: Symbols.payments,
  );

  /// Tutorial para el paso 4: Imagen principal
  static const TutorialStep mainImageStep = TutorialStep(
    title: '📸 Imagen principal',
    description: 'Sube una imagen que represente tu servicio. Esta será la primera imagen que vean los clientes.',
    tips: [
      'Usa imágenes de alta calidad',
      'Muestra tu trabajo terminado',
      'Evita imágenes borrosas o oscuras',
      'La imagen debe relacionarse con tu servicio',
    ],
    icon: Symbols.image,
  );

  /// Tutorial para el paso 5: Experiencia
  static const TutorialStep experienceStep = TutorialStep(
    title: '⭐ Tu experiencia',
    description: 'Cuéntales a los clientes sobre tu experiencia y trayectoria. Esto genera confianza y credibilidad.',
    tips: [
      'Menciona años de experiencia',
      'Habla de trabajos importantes',
      'Incluye certificaciones si las tienes',
      'Este paso es opcional pero muy valioso',
    ],
    icon: Symbols.star,
  );

  /// Tutorial para el paso 6: Contacto
  static const TutorialStep contactStep = TutorialStep(
    title: '📱 Información de contacto',
    description: 'Agrega formas adicionales para que te contacten. Más opciones de contacto = más oportunidades.',
    tips: [
      'WhatsApp es muy usado en Colombia',
      'Agrega teléfonos fijos si tienes',
      'Las redes sociales muestran profesionalismo',
      'Todos los campos son opcionales',
    ],
    icon: Symbols.contact_phone,
  );

  /// Tutorial para el paso 7: Disponibilidad
  static const TutorialStep availabilityStep = TutorialStep(
    title: '📅 Días disponibles',
    description: 'Selecciona los días que puedes trabajar. Los clientes sabrán cuándo pueden contactarte.',
    tips: [
      'Selecciona todos los días que trabajas',
      'Puedes coordinar horarios específicos después',
      'Más días disponibles = más oportunidades',
      'Este paso es opcional',
    ],
    icon: Symbols.schedule,
  );

  /// Tutorial para el paso 8: Habilidades especiales
  static const TutorialStep skillsStep = TutorialStep(
    title: '🏆 Habilidades especiales',
    description: 'Selecciona características que te destaquen. También puedes agregar habilidades personalizadas.',
    tips: [
      'Selecciona lo que realmente ofreces',
      'Las garantías dan confianza',
      'Agrega habilidades únicas en el campo personalizado',
      'No exageres, sé honesto',
    ],
    icon: Symbols.verified,
  );

  /// Tutorial para el paso 9: Imágenes adicionales
  static const TutorialStep additionalImagesStep = TutorialStep(
    title: '🖼️ Galería de trabajos',
    description: 'Sube hasta 6 imágenes de trabajos anteriores. Esto demuestra la calidad de tu trabajo.',
    tips: [
      'Máximo 6 imágenes adicionales',
      'Muestra trabajos terminados',
      'Usa imágenes desde diferentes ángulos',
      'Este paso es opcional pero muy recomendado',
    ],
    icon: Symbols.photo_library,
  );

  /// Tutorial para el paso 10: Ubicación
  static const TutorialStep locationStep = TutorialStep(
    title: '📍 Ubicación y modalidad',
    description: 'Define dónde ofreces tu servicio: a domicilio, en tu local, o ambos. También puedes agregar tu dirección.',
    tips: [
      'El mapa te ayuda a ser más preciso',
      'A domicilio es muy solicitado',
      'Si tienes local, agrégalo como opción',
      'La ubicación ayuda a clientes cercanos',
    ],
    icon: Symbols.location_on,
  );

  /// Tutorial para el paso 11: Resumen
  static const TutorialStep summaryStep = TutorialStep(
    title: '✅ ¡Casi listo!',
    description: 'Aquí puedes revisar toda la información antes de publicar tu servicio. Verifica que todo esté correcto.',
    tips: [
      'Revisa que toda la información sea correcta',
      'Tu servicio será visible inmediatamente',
      'Podrás editarlo después si necesitas cambios',
    ],
    icon: Symbols.check_circle,
  );

  /// Lista de todos los pasos del tutorial en orden
  static const List<TutorialStep> allSteps = [
    categoryStep,        // Paso 1
    basicInfoStep,       // Paso 2
    pricingStep,         // Paso 3
    mainImageStep,       // Paso 4
    experienceStep,      // Paso 5
    contactStep,         // Paso 6
    availabilityStep,    // Paso 7
    skillsStep,          // Paso 8
    additionalImagesStep,// Paso 9
    locationStep,        // Paso 10
    summaryStep,         // Paso 11
  ];

  /// Obtiene el tutorial para un paso específico
  static TutorialStep? getStepTutorial(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < allSteps.length) {
      return allSteps[stepIndex];
    }
    return null;
  }
}
