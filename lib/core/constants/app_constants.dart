class AppConstants {
  // App Info
  static const String appName = 'ServicioConecta';
  static const String appVersion = '1.0.0';
  
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
  static const String firstTimeKey = 'first_time';
  static const String themeKey = 'theme_mode';
  
  // Service Categories
  static const List<String> serviceCategories = [
    'Plomería',
    'Electricidad',
    'Limpieza',
    'Jardinería',
    'Carpintería',
    'Pintura',
    'Mecánica',
    'Tecnología',
    'Tutoría',
    'Otros'
  ];
  
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
} 