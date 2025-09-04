import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../domain/usecases/reviews/get_service_review_stats_usecase.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../data/services/firestore_service.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../core/utils/location_utils.dart';
import '../location/location_bloc.dart';
import '../location/location_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetServiceReviewStatsUseCase _getServiceReviewStatsUseCase;
  final FirestoreService _firestoreService;
  final LocationBloc _locationBloc;

  HomeBloc({
    required GetServiceReviewStatsUseCase getServiceReviewStatsUseCase,
    required FirestoreService firestoreService,
    required LocationBloc locationBloc,
  }) : _getServiceReviewStatsUseCase = getServiceReviewStatsUseCase,
       _firestoreService = firestoreService,
       _locationBloc = locationBloc,
       super(HomeInitial()) {
    on<LoadHomeServices>(_onLoadHomeServices);
    on<RefreshHomeServices>(_onRefreshHomeServices);
  }

  Future<void> _onLoadHomeServices(
    LoadHomeServices event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    await _loadServices(emit);
  }

  Future<void> _onRefreshHomeServices(
    RefreshHomeServices event,
    Emitter<HomeState> emit,
  ) async {
    await _loadServices(emit);
  }

  Future<void> _loadServices(Emitter<HomeState> emit) async {
    try {
      developer.Timeline.startSync('home_load_services');
      
      // Obtener ubicación del usuario desde LocationBloc centralizado
      double? lat;
      double? lng;
      final locationState = _locationBloc.state;
      if (locationState is LocationLoaded) {
        lat = locationState.latitude;
        lng = locationState.longitude;
        developer.log('📍 Usando ubicación del LocationBloc: ${locationState.address}', name: 'HomeBloc');
      } else {
        // Fallback: intentar obtener desde cache si LocationBloc no tiene ubicación
        final userLocation = await LocationUtils.getCachedUserLocation();
        if (userLocation != null) {
          lat = userLocation['latitude'];
          lng = userLocation['longitude'];
          developer.log('📍 Usando ubicación desde cache como fallback', name: 'HomeBloc');
        } else {
          developer.log('⚠️ No hay ubicación disponible para servicios cercanos', name: 'HomeBloc');
        }
      }

      // Variables para almacenar resultados finales
      List<ServiceEntity> featuredServices = [];
      List<ServiceEntity> nearbyServices = [];
      
      // ESTRATEGIA SECUENCIAL: Cargar servicios uno por uno y emitir al final
      try {
        // Cargar servicios destacados
        final featuredResult = await _loadFeaturedServices();
        featuredServices = featuredResult;
        developer.log('⚡ Destacados cargados: ${featuredServices.length}');
        
        // Cargar servicios cercanos
        final nearbyResult = await _loadNearbyServices(lat, lng);
        nearbyServices = nearbyResult;
        developer.log('⚡ Cercanos cargados: ${nearbyServices.length}');
        
        // Emitir resultado final solo una vez
        if (!emit.isDone) {
          emit(HomeLoaded(
            featuredServices: featuredServices,
            nearbyServices: nearbyServices,
            isFromCache: false,
          ));
        }
        
      } catch (e) {
        developer.log('❌ Error cargando servicios específicos: $e');
        if (!emit.isDone) {
          emit(HomeError('Error al cargar servicios: ${e.toString()}'));
        }
      }

      developer.log('✅ Servicios optimizados cargados: ${featuredServices.length} destacados, ${nearbyServices.length} cercanos');

    } catch (e) {
      developer.log('❌ Error al cargar servicios: $e');
      if (!emit.isDone) {
        emit(HomeError('Error al cargar servicios: ${e.toString()}'));
      }
    } finally {
      developer.Timeline.finishSync();
    }
  }

  /// Cargar servicios destacados
  Future<List<ServiceEntity>> _loadFeaturedServices() async {
    try {
      // Usar query directa sin callbacks para evitar emit tardío
      final services = await _firestoreService.getFeaturedServices(limit: 5);
      return await _optimizeServiceStats(services);
    } catch (e) {
      developer.log('❌ Error cargando servicios destacados: $e');
      return [];
    }
  }

  /// Cargar servicios cercanos
  Future<List<ServiceEntity>> _loadNearbyServices(double? lat, double? lng) async {
    try {
      if (lat == null || lng == null) {
        developer.log('⚠️ Sin ubicación para servicios cercanos');
        return [];
      }
      
      // Usar query directa sin callbacks para evitar emit tardío
      final services = await _firestoreService.getNearbyServices(
        userLatitude: lat,
        userLongitude: lng,
        radiusKm: 15.0,
        limit: 6,
      );
      return await _optimizeServiceStats(services);
    } catch (e) {
      developer.log('❌ Error cargando servicios cercanos: $e');
      return [];
    }
  }

  /// Optimizar estadísticas de servicios (solo para datos frescos)
  Future<List<ServiceEntity>> _optimizeServiceStats(List<ServiceEntity> services) async {
    return await Future.wait(services.map((service) async {
      try {
        final stats = await _getServiceReviewStatsUseCase(service.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        
        if (total == 0) return service; // mantener valores originales
        
        // Si el documento tiene valores desactualizados, usar stats reales
        if (service.reviewCount == 0 && total > 0) {
          return service.copyWith(rating: avg, reviewCount: total);
        }
        
        return service;
      } catch (e) {
        developer.log('⚠️ Error al obtener stats para servicio ${service.id}: $e');
        return service; // devolver servicio original si falla
      }
    }));
  }
}