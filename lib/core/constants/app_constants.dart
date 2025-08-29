import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// Navegación Helper
class NavigationHelper {
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context) || GoRouter.of(context).canPop();
  }
  
  static void safePop(BuildContext context) {
    if (canPop(context)) {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}

class AppConstants {
  // App Info
  static const String appName = 'Prosavis';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'La plataforma de confianza para contratar servicios locales en Colombia';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String servicesCollection = 'services';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String categoriesCollection = 'categories';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String serviceImagesPath = 'service_images';
  
  // SharedPreferences Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String recentSearchesKey = 'recent_searches';
  
  // Service Categories - 8 categorías principales en orden específico
  static const List<Map<String, dynamic>> serviceCategories = [
    {'name': 'Limpieza', 'icon': Symbols.cleaning_services, 'asset': 'assets/icons/services/limpieza.png', 'id': 1},
    {'name': 'Belleza', 'icon': Symbols.spa, 'asset': 'assets/icons/services/belleza.png', 'id': 2},
    {'name': 'Plomería', 'icon': Symbols.plumbing, 'asset': 'assets/icons/services/plomeria.png', 'id': 3},
    {'name': 'Electricidad', 'icon': Symbols.electrical_services, 'asset': 'assets/icons/services/electricidad.png', 'id': 4},
    {'name': 'Pintura', 'icon': Symbols.format_paint, 'asset': 'assets/icons/services/pintura.png', 'id': 5},
    {'name': 'Carpintería', 'icon': Symbols.construction, 'asset': 'assets/icons/services/carpinteria.png', 'id': 6},
    {'name': 'Jardinería', 'icon': Symbols.local_florist, 'asset': 'assets/icons/services/jardineria.png', 'id': 7},
    {'name': 'Mecánica', 'icon': Symbols.car_repair, 'asset': 'assets/icons/services/mecanica.png', 'id': 8}
  ];

  // Métodos auxiliares para trabajar con categorías
  static List<String> get serviceCategoryNames {
    return serviceCategories.map((category) => category['name'] as String).toList();
  }

  static String getCategoryName(Map<String, dynamic> category) {
    return category['name'] as String;
  }
  
  // API Endpoints
  static const String baseUrl = 'https://tu-api.com/api/v1';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // UI Constants
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double spacing = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Degradados suaves para secciones (inspiración estilo dinámico)
  static const List<Color> homeGradientColors = [
    Color(0xFFFFEFE5), // tono cálido claro
    Color(0xFFFDF7F2),
  ];
} 