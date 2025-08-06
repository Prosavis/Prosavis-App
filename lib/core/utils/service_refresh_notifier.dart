import 'package:flutter/foundation.dart';

/// Notificador global para cuando se necesite refrescar la lista de servicios
/// Útil para comunicar entre páginas cuando se crean, editan o eliminan servicios
class ServiceRefreshNotifier extends ChangeNotifier {
  static final ServiceRefreshNotifier _instance = ServiceRefreshNotifier._internal();
  
  factory ServiceRefreshNotifier() => _instance;
  
  ServiceRefreshNotifier._internal();

  /// Notifica que se debe refrescar la lista de servicios
  void notifyServicesChanged() {
    notifyListeners();
  }
}