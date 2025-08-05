import 'dart:math';

class LocationUtils {
  /// Calcula la distancia entre dos puntos geográficos usando la fórmula de Haversine
  /// Retorna la distancia en kilómetros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radio de la Tierra en kilómetros

    // Convertir grados a radianes
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    // Aplicar fórmula de Haversine
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  /// Convierte grados a radianes
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Formatea la distancia para mostrarla de manera legible
  /// Si es menor a 1 km, muestra en metros
  /// Si es mayor o igual a 1 km, muestra en kilómetros
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      final int distanceInMeters = (distanceInKm * 1000).round();
      return '${distanceInMeters}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.round()}km';
    }
  }

  /// Obtiene la ubicación actual del usuario para calcular distancias
  /// Retorna un Map con 'latitude' y 'longitude' o null si no se puede obtener
  static Future<Map<String, double>?> getCurrentUserLocation() async {
    try {
      // Esta función se implementará más adelante para obtener la ubicación del usuario
      // Por ahora retorna null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calcula y formatea la distancia entre el usuario actual y un servicio
  /// Retorna una cadena formateada o null si no se puede calcular
  static Future<String?> calculateDistanceToService({
    Map<String, dynamic>? serviceLocation,
  }) async {
    if (serviceLocation == null ||
        !serviceLocation.containsKey('latitude') ||
        !serviceLocation.containsKey('longitude')) {
      return null;
    }

    final userLocation = await getCurrentUserLocation();
    if (userLocation == null) {
      return null;
    }

    final double distance = calculateDistance(
      userLocation['latitude']!,
      userLocation['longitude']!,
      serviceLocation['latitude'].toDouble(),
      serviceLocation['longitude'].toDouble(),
    );

    return formatDistance(distance);
  }
}