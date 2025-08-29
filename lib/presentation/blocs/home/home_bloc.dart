import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../domain/usecases/services/get_featured_services_usecase.dart';
import '../../../domain/usecases/services/get_nearby_services_usecase.dart';
import '../../../domain/usecases/reviews/get_service_review_stats_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../core/utils/location_utils.dart';
import '../location/location_bloc.dart';
import '../location/location_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetFeaturedServicesUseCase _getFeaturedServicesUseCase;
  final GetNearbyServicesUseCase _getNearbyServicesUseCase;
  final GetServiceReviewStatsUseCase _getServiceReviewStatsUseCase;
  final LocationBloc _locationBloc;

  HomeBloc({
    required GetFeaturedServicesUseCase getFeaturedServicesUseCase,
    required GetNearbyServicesUseCase getNearbyServicesUseCase,
    required GetServiceReviewStatsUseCase getServiceReviewStatsUseCase,
    required LocationBloc locationBloc,
  }) : _getFeaturedServicesUseCase = getFeaturedServicesUseCase,
       _getNearbyServicesUseCase = getNearbyServicesUseCase,
       _getServiceReviewStatsUseCase = getServiceReviewStatsUseCase,
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

      final results = await Future.wait([
        _getFeaturedServicesUseCase(const GetFeaturedServicesParams(limit: 5)),
        _getNearbyServicesUseCase(GetNearbyServicesParams(limit: 6, radiusKm: 15, userLatitude: lat, userLongitude: lng)),
      ]);

      var featuredServices = results[0];
      var nearbyServices = results[1];

      // Ajustar rating/contador con estadísticas reales si el doc aún no reflejó agregados
      // Se hace en paralelo por rendimiento y simplicidad
      featuredServices = await Future.wait(featuredServices.map((s) async {
        final stats = await _getServiceReviewStatsUseCase(s.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        if (total == 0) return s; // mantener 0.0/0
        // Si el doc tiene 0 pero hay stats, aplicar stats para UI
        if (s.reviewCount == 0 && total > 0) {
          return s.copyWith(rating: avg, reviewCount: total);
        }
        return s;
      }));

      nearbyServices = await Future.wait(nearbyServices.map((s) async {
        final stats = await _getServiceReviewStatsUseCase(s.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        if (total == 0) return s;
        if (s.reviewCount == 0 && total > 0) {
          return s.copyWith(rating: avg, reviewCount: total);
        }
        return s;
      }));

      developer.log('✅ Servicios cargados para navegación pública: ${featuredServices.length} destacados, ${nearbyServices.length} cercanos');

      emit(HomeLoaded(
        featuredServices: featuredServices,
        nearbyServices: nearbyServices,
      ));
    } catch (e) {
      developer.log('❌ Error al cargar servicios: $e');
      emit(HomeError('Error al cargar servicios: ${e.toString()}'));
    }
  }
}