import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

      // Obtener ubicación actual
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
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

  /// Obtiene la dirección actual basada en GPS real
  /// Retorna una cadena con la dirección o null si no se puede obtener
  static Future<String?> getCurrentAddress() async {
    try {
      // Verificar permisos
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        throw Exception('Permisos de ubicación denegados');
      }

      // Obtener ubicación actual
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

        // Convertir coordenadas a dirección
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        
        // Construir dirección en formato colombiano
        final List<String> addressParts = [];
        
        // Añadir calle/carrera si está disponible
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        
        // Añadir número si está disponible
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          if (addressParts.isNotEmpty) {
            addressParts[addressParts.length - 1] += ' #${place.subThoroughfare}';
          } else {
            addressParts.add('#${place.subThoroughfare}');
          }
        }
        
        // Añadir localidad/barrio
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        // Añadir ciudad
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        // Añadir departamento/estado
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        // Añadir país
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        return addressParts.join(', ');
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

      // Obtener ubicación actual
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Obtener dirección
      final address = await getCurrentAddress();

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