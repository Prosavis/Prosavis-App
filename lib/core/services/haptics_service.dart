import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Servicio centralizado para feedback háptico.
///
/// Unifica los distintos tipos de vibración/impacto y permite
/// cambiar su comportamiento en un solo lugar.
class HapticsService {
  HapticsService._();

  /// Activa un feedback sutil al navegar (push/pop o cambio de pestaña).
  static Future<void> onNavigation() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Acciones primarias (botones CTA, como contactar por WhatsApp).
  static Future<void> onPrimaryAction() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  /// Éxito de una operación (p. ej. servicio creado correctamente).
  static Future<void> onSuccess() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  /// Avisos o validaciones (opcional para errores no críticos).
  static Future<void> onWarning() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }
}

/// Observador de navegación que dispara hápticos al hacer push/pop de rutas.
class HapticsRouteObserver extends NavigatorObserver {
  bool _didInitialPush = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Evitar vibración en el primer push del arranque.
    if (!_didInitialPush) {
      _didInitialPush = true;
      return;
    }
    HapticsService.onNavigation();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    HapticsService.onNavigation();
  }
}


