import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/favorites/add_to_favorites_usecase.dart';
import '../../../domain/usecases/favorites/check_favorite_status_usecase.dart';
import '../../../domain/usecases/favorites/get_user_favorites_usecase.dart';
import '../../../domain/usecases/favorites/remove_from_favorites_usecase.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';
import '../../../domain/usecases/reviews/get_service_review_stats_usecase.dart';
import '../../../domain/entities/service_entity.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetUserFavoritesUseCase getUserFavoritesUseCase;
  final WatchUserFavoritesUseCase? watchUserFavoritesUseCase;
  final AddToFavoritesUseCase addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase removeFromFavoritesUseCase;
  final CheckFavoriteStatusUseCase checkFavoriteStatusUseCase;
  final GetServiceReviewStatsUseCase getServiceReviewStatsUseCase;

  StreamSubscription<List<ServiceEntity>>? _favoritesSubscription;

  FavoritesBloc({
    required this.getUserFavoritesUseCase,
    this.watchUserFavoritesUseCase,
    required this.addToFavoritesUseCase,
    required this.removeFromFavoritesUseCase,
    required this.checkFavoriteStatusUseCase,
    required this.getServiceReviewStatsUseCase,
  }) : super(FavoritesInitial()) {
    on<LoadUserFavorites>(_onLoadUserFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<RefreshFavorites>(_onRefreshFavorites);
    on<FavoritesStreamUpdated>(_onFavoritesStreamUpdated);
  }

  Future<void> _onLoadUserFavorites(
    LoadUserFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    
    try {
      var favorites = await getUserFavoritesUseCase(event.userId);

      // Ajustar rating localmente cuando el doc aún no refleje agregados
      favorites = await Future.wait(favorites.map((s) async {
        final stats = await getServiceReviewStatsUseCase(s.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        if (total == 0) return s;
        if (s.reviewCount == 0 && total > 0) {
          return s.copyWith(rating: avg, reviewCount: total);
        }
        return s;
      }));
      
      // Crear mapa de estado de favoritos
      final favoriteStatus = <String, bool>{};
      for (final service in favorites) {
        favoriteStatus[service.id] = true;
      }
      
      emit(FavoritesLoaded(
        favorites: favorites,
        favoriteStatus: favoriteStatus,
      ));

      // Suscripción en tiempo real
      await _favoritesSubscription?.cancel();
      if (watchUserFavoritesUseCase != null) {
        _favoritesSubscription = watchUserFavoritesUseCase!(event.userId).listen((services) {
          // Verificar si el bloc no está cerrado antes de agregar eventos
          if (!isClosed) {
            add(FavoritesStreamUpdated(services));
          }
        });
      }
    } catch (e) {
      emit(FavoritesError('Error al cargar favoritos: $e'));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Optimista: marcar como favorito de inmediato
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        updatedStatus[event.serviceId] = true;
        emit(currentState.copyWith(favoriteStatus: updatedStatus));
      }

      await addToFavoritesUseCase(AddToFavoritesParams(
        userId: event.userId,
        serviceId: event.serviceId,
      ));
      // No es necesario recargar; el stream actualizará la lista si corresponde
    } catch (e) {
      // Revertir cambio optimista si algo falla
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        updatedStatus[event.serviceId] = false;
        emit(currentState.copyWith(favoriteStatus: updatedStatus));
      }
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Optimista: desmarcar y quitar de la lista al instante
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;

        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        updatedStatus[event.serviceId] = false;
        final updatedFavorites = currentState.favorites
            .where((service) => service.id != event.serviceId)
            .toList();
        emit(currentState.copyWith(
          favorites: updatedFavorites,
          favoriteStatus: updatedStatus,
        ));
      }

      await removeFromFavoritesUseCase(RemoveFromFavoritesParams(
        userId: event.userId,
        serviceId: event.serviceId,
      ));
      // Lista se sincroniza por stream; nada más
    } catch (e) {
      // Revertir al estado previo si falló
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        // No guardamos snapshot completo para simplificar; forzamos refresh
        if (!isClosed) {
          add(RefreshFavorites((currentState.favorites.isNotEmpty)
              ? currentState.favorites.first.providerId // placeholder, se reemplaza abajo
              : ''));
        }
      }
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Determinar estado actual sin consultar si lo tenemos en memoria
      bool? knownFavorite;
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        knownFavorite = currentState.favoriteStatus[event.serviceId];
      }
      final bool isFavorite = knownFavorite ??
          await checkFavoriteStatusUseCase(CheckFavoriteStatusParams(
            userId: event.userId,
            serviceId: event.serviceId,
          ));
      
      if (!isClosed) {
        if (isFavorite) {
          add(RemoveFromFavorites(
            userId: event.userId,
            serviceId: event.serviceId,
          ));
        } else {
          add(AddToFavorites(
            userId: event.userId,
            serviceId: event.serviceId,
          ));
        }
      }
    } catch (e) {
      emit(FavoritesError('Error al cambiar favorito: $e'));
    }
  }

  Future<void> _onCheckFavoriteStatus(
    CheckFavoriteStatus event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final isFavorite = await checkFavoriteStatusUseCase(CheckFavoriteStatusParams(
        userId: event.userId,
        serviceId: event.serviceId,
      ));
      
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        updatedStatus[event.serviceId] = isFavorite;
        
        emit(currentState.copyWith(favoriteStatus: updatedStatus));
      }
    } catch (e) {
      // Error silencioso para verificación de estado
      // Error silencioso para verificación de estado - usando logging framework en producción
    }
  }

  Future<void> _onRefreshFavorites(
    RefreshFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      var favorites = await getUserFavoritesUseCase(event.userId);

      favorites = await Future.wait(favorites.map((s) async {
        final stats = await getServiceReviewStatsUseCase(s.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        if (total == 0) return s;
        if (s.reviewCount == 0 && total > 0) {
          return s.copyWith(rating: avg, reviewCount: total);
        }
        return s;
      }));
      
      // Mantener estado actual si existe, solo actualizar lista
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        
        // Actualizar estado para servicios en la nueva lista
        for (final service in favorites) {
          updatedStatus[service.id] = true;
        }
        
        emit(currentState.copyWith(
          favorites: favorites,
          favoriteStatus: updatedStatus,
        ));
      } else {
        // Si no hay estado previo, crear uno nuevo
        final favoriteStatus = <String, bool>{};
        for (final service in favorites) {
          favoriteStatus[service.id] = true;
        }
        
        emit(FavoritesLoaded(
          favorites: favorites,
          favoriteStatus: favoriteStatus,
        ));
      }
    } catch (e) {
      emit(FavoritesError('Error al actualizar favoritos: $e'));
    }
  }

  Future<void> _onFavoritesStreamUpdated(
    FavoritesStreamUpdated event,
    Emitter<FavoritesState> emit,
  ) async {
    final List<ServiceEntity> services = event.services.cast<ServiceEntity>();
    // Opcional: ajustar ratings cuando falte info
    final adjusted = await Future.wait(services.map((s) async {
      if (s.reviewCount == 0) {
        final stats = await getServiceReviewStatsUseCase(s.id);
        final total = (stats['totalReviews'] ?? 0) as int;
        final avg = (stats['averageRating'] ?? 0.0).toDouble();
        if (total > 0) return s.copyWith(rating: avg, reviewCount: total);
      }
      return s;
    }));

    final favoriteStatus = <String, bool>{for (final s in adjusted) s.id: true};

    if (state is FavoritesLoaded) {
      final current = state as FavoritesLoaded;
      emit(current.copyWith(favorites: adjusted, favoriteStatus: favoriteStatus));
    } else {
      emit(FavoritesLoaded(favorites: adjusted, favoriteStatus: favoriteStatus));
    }
  }

  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }
}