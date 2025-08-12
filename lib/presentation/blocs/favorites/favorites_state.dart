import 'package:equatable/equatable.dart';

import '../../../domain/entities/service_entity.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<ServiceEntity> favorites;
  final Map<String, bool> favoriteStatus; // serviceId -> isFavorite

  const FavoritesLoaded({
    required this.favorites,
    this.favoriteStatus = const {},
  });

  @override
  List<Object?> get props => [favorites, favoriteStatus];

  FavoritesLoaded copyWith({
    List<ServiceEntity>? favorites,
    Map<String, bool>? favoriteStatus,
  }) {
    return FavoritesLoaded(
      favorites: favorites ?? this.favorites,
      favoriteStatus: favoriteStatus ?? this.favoriteStatus,
    );
  }

  bool isFavorite(String serviceId) {
    return favoriteStatus[serviceId] ?? false;
  }
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

class FavoriteToggling extends FavoritesState {
  final String serviceId;
  final List<ServiceEntity> favorites;
  final Map<String, bool> favoriteStatus;

  const FavoriteToggling({
    required this.serviceId,
    required this.favorites,
    required this.favoriteStatus,
  });

  @override
  List<Object?> get props => [serviceId, favorites, favoriteStatus];
}

class FavoriteToggled extends FavoritesState {
  final String serviceId;
  final bool isFavorite;
  final List<ServiceEntity> favorites;
  final Map<String, bool> favoriteStatus;

  const FavoriteToggled({
    required this.serviceId,
    required this.isFavorite,
    required this.favorites,
    required this.favoriteStatus,
  });

  @override
  List<Object?> get props => [serviceId, isFavorite, favorites, favoriteStatus];
}

/// Error no bloqueante para acciones (agregar/quitar)
class FavoritesActionError extends FavoritesState {
  final String message;
  const FavoritesActionError(this.message);

  @override
  List<Object?> get props => [message];
}