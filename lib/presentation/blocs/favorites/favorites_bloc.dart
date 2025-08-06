import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/favorites/add_to_favorites_usecase.dart';
import '../../../domain/usecases/favorites/check_favorite_status_usecase.dart';
import '../../../domain/usecases/favorites/get_user_favorites_usecase.dart';
import '../../../domain/usecases/favorites/remove_from_favorites_usecase.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetUserFavoritesUseCase getUserFavoritesUseCase;
  final AddToFavoritesUseCase addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase removeFromFavoritesUseCase;
  final CheckFavoriteStatusUseCase checkFavoriteStatusUseCase;

  FavoritesBloc({
    required this.getUserFavoritesUseCase,
    required this.addToFavoritesUseCase,
    required this.removeFromFavoritesUseCase,
    required this.checkFavoriteStatusUseCase,
  }) : super(FavoritesInitial()) {
    on<LoadUserFavorites>(_onLoadUserFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<RefreshFavorites>(_onRefreshFavorites);
  }

  Future<void> _onLoadUserFavorites(
    LoadUserFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    
    try {
      final favorites = await getUserFavoritesUseCase(event.userId);
      
      // Crear mapa de estado de favoritos
      final favoriteStatus = <String, bool>{};
      for (final service in favorites) {
        favoriteStatus[service.id] = true;
      }
      
      emit(FavoritesLoaded(
        favorites: favorites,
        favoriteStatus: favoriteStatus,
      ));
    } catch (e) {
      emit(FavoritesError('Error al cargar favoritos: $e'));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await addToFavoritesUseCase(AddToFavoritesParams(
        userId: event.userId,
        serviceId: event.serviceId,
      ));
      
      // Actualizar estado local
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        updatedStatus[event.serviceId] = true;
        
        emit(currentState.copyWith(favoriteStatus: updatedStatus));
      }
      
      // Recargar favoritos para obtener la lista actualizada
      add(RefreshFavorites(event.userId));
    } catch (e) {
      emit(FavoritesError('Error al agregar a favoritos: $e'));
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await removeFromFavoritesUseCase(RemoveFromFavoritesParams(
        userId: event.userId,
        serviceId: event.serviceId,
      ));
      
      // Actualizar estado local
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedStatus = Map<String, bool>.from(currentState.favoriteStatus);
        updatedStatus[event.serviceId] = false;
        
        // Remover de la lista de favoritos
        final updatedFavorites = currentState.favorites
            .where((service) => service.id != event.serviceId)
            .toList();
        
        emit(currentState.copyWith(
          favorites: updatedFavorites,
          favoriteStatus: updatedStatus,
        ));
      }
    } catch (e) {
      emit(FavoritesError('Error al quitar de favoritos: $e'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Mostrar estado de carga para este servicio específico
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        emit(FavoriteToggling(
          serviceId: event.serviceId,
          favorites: currentState.favorites,
          favoriteStatus: currentState.favoriteStatus,
        ));
      }
      
      // Verificar estado actual
      final isFavorite = await checkFavoriteStatusUseCase(CheckFavoriteStatusParams(
        userId: event.userId,
        serviceId: event.serviceId,
      ));
      
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
      final favorites = await getUserFavoritesUseCase(event.userId);
      
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
}