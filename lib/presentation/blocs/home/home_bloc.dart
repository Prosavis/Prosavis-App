import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../domain/usecases/services/get_featured_services_usecase.dart';
import '../../../domain/usecases/services/get_nearby_services_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetFeaturedServicesUseCase _getFeaturedServicesUseCase;
  final GetNearbyServicesUseCase _getNearbyServicesUseCase;

  HomeBloc({
    required GetFeaturedServicesUseCase getFeaturedServicesUseCase,
    required GetNearbyServicesUseCase getNearbyServicesUseCase,
  }) : _getFeaturedServicesUseCase = getFeaturedServicesUseCase,
       _getNearbyServicesUseCase = getNearbyServicesUseCase,
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
      developer.log('🏠 Cargando servicios para navegación pública...');
      
      // Cargar servicios destacados y cercanos en paralelo (sin autenticación)
      final results = await Future.wait([
        _getFeaturedServicesUseCase(const GetFeaturedServicesParams(limit: 5)),
        _getNearbyServicesUseCase(const GetNearbyServicesParams(limit: 3)),
      ]);

      final featuredServices = results[0];
      final nearbyServices = results[1];

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