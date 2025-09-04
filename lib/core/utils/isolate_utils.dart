import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../data/models/service_model.dart';
import '../../domain/entities/service_entity.dart';

/// Utilidades para procesamiento en isolates separados
/// Mueve tareas pesadas fuera del hilo principal para evitar jank
class IsolateUtils {
  
  /// Parse múltiples servicios en un isolate separado
  /// Input: List de Maps (datos crudos de Firestore)
  /// Output: List de ServiceEntity procesados
  static Future<List<ServiceEntity>> parseServicesInIsolate(
    List<Map<String, dynamic>> rawServicesData
  ) async {
    developer.Timeline.startSync('parse_services_isolate');
    
    try {
      if (rawServicesData.isEmpty) {
        developer.log('📝 Lista de servicios vacía, retornando lista vacía');
        return [];
      }
      
      developer.log('🔄 Procesando ${rawServicesData.length} servicios en isolate separado');
      
      // Usar compute() para procesar en un isolate separado
      final parsedServices = await compute(_parseServicesWorker, rawServicesData);
      
      developer.log('✅ ${parsedServices.length} servicios procesados exitosamente en isolate');
      return parsedServices;
      
    } catch (e) {
      developer.log('⚠️ Error al procesar servicios en isolate: $e');
      // Fallback: procesar en el hilo principal si el isolate falla
      return _parseServicesWorker(rawServicesData);
    } finally {
      developer.Timeline.finishSync();
    }
  }
  
  /// Parse múltiples servicios con filtrado en isolate
  /// Útil para listas grandes que necesitan filtrado adicional
  static Future<List<ServiceEntity>> parseAndFilterServicesInIsolate({
    required List<Map<String, dynamic>> rawServicesData,
    String? categoryFilter,
    double? minRating,
    bool activeOnly = true,
  }) async {
    developer.Timeline.startSync('parse_filter_services_isolate');
    
    try {
      final filterParams = ServiceFilterParams(
        rawData: rawServicesData,
        categoryFilter: categoryFilter,
        minRating: minRating,
        activeOnly: activeOnly,
      );
      
      developer.log('🔄 Procesando y filtrando ${rawServicesData.length} servicios en isolate');
      
      final filteredServices = await compute(_parseAndFilterServicesWorker, filterParams);
      
      developer.log('✅ ${filteredServices.length} servicios procesados y filtrados en isolate');
      return filteredServices;
      
    } catch (e) {
      developer.log('⚠️ Error al procesar y filtrar servicios en isolate: $e');
      // Fallback: procesar en el hilo principal
      return _parseAndFilterServicesWorker(ServiceFilterParams(
        rawData: rawServicesData,
        categoryFilter: categoryFilter,
        minRating: minRating,
        activeOnly: activeOnly,
      ));
    } finally {
      developer.Timeline.finishSync();
    }
  }
  
  /// Parse servicios con ordenamiento en isolate
  static Future<List<ServiceEntity>> parseAndSortServicesInIsolate({
    required List<Map<String, dynamic>> rawServicesData,
    required ServiceSortType sortType,
    bool ascending = false,
  }) async {
    developer.Timeline.startSync('parse_sort_services_isolate');
    
    try {
      final sortParams = ServiceSortParams(
        rawData: rawServicesData,
        sortType: sortType,
        ascending: ascending,
      );
      
      developer.log('🔄 Procesando y ordenando ${rawServicesData.length} servicios en isolate');
      
      final sortedServices = await compute(_parseAndSortServicesWorker, sortParams);
      
      developer.log('✅ ${sortedServices.length} servicios procesados y ordenados en isolate');
      return sortedServices;
      
    } catch (e) {
      developer.log('⚠️ Error al procesar y ordenar servicios en isolate: $e');
      return _parseAndSortServicesWorker(ServiceSortParams(
        rawData: rawServicesData,
        sortType: sortType,
        ascending: ascending,
      ));
    } finally {
      developer.Timeline.finishSync();
    }
  }
}

// === WORKERS PARA ISOLATES ===

/// Worker para parsear servicios (se ejecuta en isolate separado)
List<ServiceEntity> _parseServicesWorker(List<Map<String, dynamic>> rawData) {
  return rawData.map((data) {
    try {
      return ServiceModel.fromJson(data) as ServiceEntity;
    } catch (e) {
      // Log del error pero continuar con otros servicios
      debugPrint('⚠️ Error parseando servicio ${data['id']}: $e');
      return null;
    }
  }).where((service) => service != null).cast<ServiceEntity>().toList();
}

/// Worker para parsear y filtrar servicios
List<ServiceEntity> _parseAndFilterServicesWorker(ServiceFilterParams params) {
  final services = _parseServicesWorker(params.rawData);
  
  return services.where((service) {
    // Filtrar por activo
    if (params.activeOnly && !service.isActive) {
      return false;
    }
    
    // Filtrar por categoría
    if (params.categoryFilter != null && 
        service.category != params.categoryFilter) {
      return false;
    }
    
    // Filtrar por rating mínimo
    if (params.minRating != null && 
        service.rating < params.minRating!) {
      return false;
    }
    
    return true;
  }).toList();
}

/// Worker para parsear y ordenar servicios
List<ServiceEntity> _parseAndSortServicesWorker(ServiceSortParams params) {
  final services = _parseServicesWorker(params.rawData);
  
  services.sort((a, b) {
    int comparison = 0;
    
    switch (params.sortType) {
      case ServiceSortType.rating:
        comparison = a.rating.compareTo(b.rating);
        break;
      case ServiceSortType.price:
        comparison = a.price.compareTo(b.price);
        break;
      case ServiceSortType.createdAt:
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
      case ServiceSortType.title:
        comparison = a.title.compareTo(b.title);
        break;
      case ServiceSortType.reviewCount:
        comparison = a.reviewCount.compareTo(b.reviewCount);
        break;
    }
    
    return params.ascending ? comparison : -comparison;
  });
  
  return services;
}

// === CLASES DE PARÁMETROS ===

/// Parámetros para filtrado de servicios
class ServiceFilterParams {
  final List<Map<String, dynamic>> rawData;
  final String? categoryFilter;
  final double? minRating;
  final bool activeOnly;
  
  ServiceFilterParams({
    required this.rawData,
    this.categoryFilter,
    this.minRating,
    this.activeOnly = true,
  });
}

/// Parámetros para ordenamiento de servicios
class ServiceSortParams {
  final List<Map<String, dynamic>> rawData;
  final ServiceSortType sortType;
  final bool ascending;
  
  ServiceSortParams({
    required this.rawData,
    required this.sortType,
    this.ascending = false,
  });
}

/// Tipos de ordenamiento para servicios
enum ServiceSortType {
  rating,
  price,
  createdAt,
  title,
  reviewCount,
}
