import 'package:shared_preferences/shared_preferences.dart';
import '../injection/injection_container.dart';
import '../../domain/usecases/services/get_user_services_usecase.dart';
import 'logging_service.dart';

/// Servicio para gestionar el estado de los tutoriales en la aplicación
class TutorialService {
  static const String _hasSeenServiceCreationTutorialKey = 'has_seen_service_creation_tutorial';
  
  /// Verifica si el usuario ya vio el tutorial de creación de servicios
  static Future<bool> hasSeenServiceCreationTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenServiceCreationTutorialKey) ?? false;
    } catch (e) {
      // En caso de error, asumir que no ha visto el tutorial
      return false;
    }
  }
  
  /// Marca que el usuario ya vio el tutorial de creación de servicios
  static Future<void> markServiceCreationTutorialAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenServiceCreationTutorialKey, true);
    } catch (e) {
      // Registrar error pero no fallar la operación
      LoggingService.logError(
        e,
        StackTrace.current,
        reason: 'Error al marcar tutorial como visto en SharedPreferences',
        additionalData: {'tutorial_key': _hasSeenServiceCreationTutorialKey},
      );
    }
  }
  
  /// Resetea el estado del tutorial (útil para testing)
  static Future<void> resetServiceCreationTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasSeenServiceCreationTutorialKey);
    } catch (e) {
      LoggingService.logError(
        e,
        StackTrace.current,
        reason: 'Error al resetear estado del tutorial en SharedPreferences',
        additionalData: {'tutorial_key': _hasSeenServiceCreationTutorialKey},
      );
    }
  }
  
  /// Verifica si el usuario tiene servicios creados
  static Future<bool> userHasServices(String userId) async {
    try {
      final getUserServicesUseCase = sl<GetUserServicesUseCase>();
      final services = await getUserServicesUseCase(userId);
      return services.isNotEmpty;
    } catch (e) {
      // En caso de error, asumir que no tiene servicios
      LoggingService.logError(
        e,
        StackTrace.current,
        reason: 'Error al verificar servicios del usuario para tutorial',
        additionalData: {'user_id': userId},
      );
      return false;
    }
  }
  
  /// Verifica si el usuario debería ver el tutorial basado en si tiene servicios
  /// y si ya vio el tutorial anteriormente
  static Future<bool> shouldShowServiceCreationTutorial(String userId) async {
    LoggingService.logInfo(
      'Verificando si mostrar tutorial de creación de servicios',
      category: 'Tutorial',
      data: {'user_id': userId},
    );
    
    // Verificar si ya tiene servicios creados
    final hasServices = await userHasServices(userId);
    if (hasServices) {
      LoggingService.logInfo(
        'Tutorial no se mostrará: usuario ya tiene servicios creados',
        category: 'Tutorial',
      );
      return false;
    }
    
    // Si no tiene servicios, verificar si ya vio el tutorial
    final hasSeenTutorial = await hasSeenServiceCreationTutorial();
    final shouldShow = !hasSeenTutorial;
    
    LoggingService.logInfo(
      shouldShow 
        ? 'Tutorial se mostrará: usuario nuevo sin servicios'
        : 'Tutorial no se mostrará: usuario ya lo vio anteriormente',
      category: 'Tutorial',
      data: {'should_show': shouldShow, 'has_seen': hasSeenTutorial},
    );
    
    return shouldShow;
  }
}
