import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationUtils {
  // Cache inteligente en memoria para evitar solicitar la ubicación repetidamente
  static Map<String, double>? _cachedUserLocation;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5); // Cache válido por 5 minutos

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

  /// Verifica y solicita permisos de ubicación
  static Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }

  /// Obtiene la ubicación actual del usuario para calcular distancias
  /// Retorna un Map con 'latitude' y 'longitude' o null si no se puede obtener
  static Future<Map<String, double>?> getCurrentUserLocation() async {
    try {
      // Verificar permisos
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return null;

      // Obtener ubicación actual con timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 15), // Timeout de 15 segundos
        ),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      return null;
    }
  }

  /// Igual que `getCurrentUserLocation` pero con cache en memoria.
  /// Útil para listas de tarjetas donde se requiere la misma ubicación.
  static Future<Map<String, double>?> getCachedUserLocation({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Verificar si el cache es válido (no expirado)
    final isCacheValid = _cacheTimestamp != null && 
        _cachedUserLocation != null && 
        now.difference(_cacheTimestamp!).compareTo(_cacheValidDuration) < 0;
    
    if (!forceRefresh && isCacheValid) {
      return _cachedUserLocation;
    }
    
    final result = await getCurrentUserLocation();
    if (result != null) {
      _cachedUserLocation = result;
      _cacheTimestamp = now;
    }
    return result;
  }

  /// Obtiene la dirección actual basada en GPS real
  /// Retorna una cadena con la dirección o null si no se puede obtener
  static Future<String?> getCurrentAddress() async {
    try {
      // Verificar permisos
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        throw Exception('Permisos de ubicación denegados');
      }

      // Obtener ubicación actual con timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 15), // Timeout de 15 segundos
        ),
      );

        // Convertir coordenadas a dirección
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return composeAddressFromPlacemark(placemarks.first);
      }

      return null;
    } catch (e) {
      // En caso de error, retornar null para que se maneje en la UI
      return null;
    }
  }

  /// Obtiene información detallada de la ubicación actual
  /// Retorna un Map con coordenadas y dirección o null si no se puede obtener
  static Future<Map<String, dynamic>?> getCurrentLocationDetails() async {
    try {
      // Verificar permisos
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return null;

      // Obtener ubicación actual con timeout para evitar esperas indefinidas
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 15), // Timeout de 15 segundos
        ),
      );

      // Obtener dirección usando la posición ya obtenida (evitar doble llamada GPS)
      String? address;
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          address = composeAddressFromPlacemark(placemarks.first);
        }
      } catch (e) {
        // Si falla el geocoding, intentar crear una dirección aproximada
        try {
          // Intentar geocoding reverso con timeout más corto
          final List<Placemark> fallbackPlacemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 5));
          
          if (fallbackPlacemarks.isNotEmpty) {
            address = composeAddressFromPlacemark(fallbackPlacemarks.first);
          }
        } catch (e2) {
          // Crear dirección aproximada usando coordenadas conocidas de Colombia
          address = _createApproximateAddress(position.latitude, position.longitude);
        }
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
        'timestamp': position.timestamp.toIso8601String(),
        'address': address,
      };
    } catch (e) {
      return null;
    }
  }

  /// Abre la configuración de ubicación del dispositivo
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      return false;
    }
  }

  /// Abre la configuración de permisos de la aplicación
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Crea una dirección aproximada basada en coordenadas conocidas de Colombia
  static String _createApproximateAddress(double latitude, double longitude) {
    // Coordenadas aproximadas de principales ciudades de Colombia
    const List<Map<String, dynamic>> colombianCities = [
      {'name': 'Bogotá, Cundinamarca', 'lat': 4.7110, 'lng': -74.0721},
      {'name': 'Medellín, Antioquia', 'lat': 6.2442, 'lng': -75.5812},
      {'name': 'Cali, Valle del Cauca', 'lat': 3.4516, 'lng': -76.5320},
      {'name': 'Barranquilla, Atlántico', 'lat': 10.9685, 'lng': -74.7813},
      {'name': 'Cartagena, Bolívar', 'lat': 10.3910, 'lng': -75.4794},
      {'name': 'Bucaramanga, Santander', 'lat': 7.1253, 'lng': -73.1198},
      {'name': 'Pereira, Risaralda', 'lat': 4.8133, 'lng': -75.6961},
      {'name': 'Manizales, Caldas', 'lat': 5.0703, 'lng': -75.5138},
      {'name': 'Ibagué, Tolima', 'lat': 4.4389, 'lng': -75.2322},
      {'name': 'Pasto, Nariño', 'lat': 1.2136, 'lng': -77.2811},
    ];

    // Encontrar la ciudad más cercana
    String closestCity = 'Colombia';
    double closestDistance = double.infinity;
    
    for (final city in colombianCities) {
      final distance = calculateDistance(
        latitude,
        longitude,
        city['lat'] as double,
        city['lng'] as double,
      );
      
      if (distance < closestDistance) {
        closestDistance = distance;
        closestCity = city['name'] as String;
      }
    }
    
    // Si está muy cerca de una ciudad conocida (menos de 50km), usar esa ciudad
    if (closestDistance < 50) {
      return closestCity;
    }
    
    // Si no, crear dirección genérica pero útil
    return 'Cerca de $closestCity, Colombia';
  }

  /// Limpia el cache de ubicación forzando una nueva detección
  static void clearLocationCache() {
    _cachedUserLocation = null;
    _cacheTimestamp = null;
  }

  /// Actualiza el cache manualmente con una ubicación
  static void updateLocationCache(Map<String, double> location) {
    _cachedUserLocation = location;
    _cacheTimestamp = DateTime.now();
  }

  /// Obtiene ubicación con estrategia de fallback mejorada
  /// Primero intenta GPS de alta precisión, luego GPS de precisión media si falla
  static Future<Map<String, double>?> getUserLocationWithFallback() async {
    try {
      // Verificar permisos
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return null;

      // Intentar primero con alta precisión y timeout corto
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            timeLimit: Duration(seconds: 10), // Timeout más agresivo
          ),
        );

        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } catch (e) {
        // Si falla alta precisión, intentar con precisión media
        try {
          final Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 50,
              timeLimit: Duration(seconds: 8), // Timeout aún más corto
            ),
          );

          return {
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        } catch (e) {
          // Como último recurso, usar la última ubicación conocida
          final Position? lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            return {
              'latitude': lastKnown.latitude,
              'longitude': lastKnown.longitude,
            };
          }
        }
      }
    } catch (e) {
      // Error general
    }
    
    return null;
  }

  /// Calcula y formatea la distancia entre el usuario actual y un servicio
  /// Retorna una cadena formateada o null si no se puede calcular
  static Future<String?> calculateDistanceToService({
    Map<String, dynamic>? serviceLocation,
  }) async {
    if (serviceLocation == null) {
      return null;
    }

    double? serviceLat;
    double? serviceLon;
    final dynamic latRaw = serviceLocation['latitude'] ?? serviceLocation['lat'];
    final dynamic lonRaw = serviceLocation['longitude'] ?? serviceLocation['lng'] ?? serviceLocation['lon'];
    if (latRaw is num) serviceLat = latRaw.toDouble();
    if (lonRaw is num) serviceLon = lonRaw.toDouble();
    if (serviceLat == null || serviceLon == null) {
      return null;
    }

    final userLocation = await getCachedUserLocation();
    if (userLocation == null) {
      return null;
    }

    final double distance = calculateDistance(
      userLocation['latitude']!,
      userLocation['longitude']!,
      serviceLat,
      serviceLon,
    );

    return formatDistance(distance);
  }

  /// Crea una línea de dirección legible a partir de un Placemark evitando
  /// duplicar numeraciones como "##" o repetir el mismo número.
  static String composeAddressFromPlacemark(Placemark place) {
    final String street = (place.street ?? '').trim();
    final String number = (place.subThoroughfare ?? '').trim();
    final String line = _mergeStreetAndNumber(street, number);

    final List<String> parts = [];
    if (line.isNotEmpty) parts.add(line);
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!.trim());
    } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!.trim());
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!.trim());
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!.trim());
    }

    return normalizeAddress(parts.join(', '));
  }

  /// Une calle y número evitando repetir si la calle ya contiene '# número'.
  static String _mergeStreetAndNumber(String street, String number) {
    if (street.isEmpty && number.isEmpty) return '';
    if (street.isEmpty) return number;
    if (number.isEmpty) return street;

    final String pattern = r'#\s*' + RegExp.escape(number);
    final RegExp re = RegExp(pattern, caseSensitive: false);
    if (re.hasMatch(street)) {
      return street; // Ya contiene el número
    }

    // Si la calle ya contiene algún '# <algo>' no añadimos otro número
    if (RegExp(r'#\s*[\w\-]+', caseSensitive: false).hasMatch(street)) {
      return street;
    }

    return '$street #$number';
  }

  /// Normaliza una dirección en texto: colapsa espacios, reemplaza '##' por '#'
  /// y quita duplicados triviales.
  static String normalizeAddress(String input) {
    String out = input.replaceAll('##', '#');
    out = out.replaceAll(RegExp(r'\s+,'), ',');
    out = out.replaceAll(RegExp(r',\s*,+'), ', ');
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Eliminar repeticiones tipo "# 85-13 # 85-13"
    out = out.replaceAllMapped(
      RegExp(r'(#\s*([\w\-]+))\s*,?\s*#\s*\2', caseSensitive: false),
      (m) => m.group(1) ?? '',
    );
    return out;
  }
}