import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserFavorites extends FavoritesEvent {
  final String userId;

  const LoadUserFavorites(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddToFavorites extends FavoritesEvent {
  final String userId;
  final String serviceId;

  const AddToFavorites({
    required this.userId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [userId, serviceId];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String userId;
  final String serviceId;

  const RemoveFromFavorites({
    required this.userId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [userId, serviceId];
}

class ToggleFavorite extends FavoritesEvent {
  final String userId;
  final String serviceId;

  const ToggleFavorite({
    required this.userId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [userId, serviceId];
}

class CheckFavoriteStatus extends FavoritesEvent {
  final String userId;
  final String serviceId;

  const CheckFavoriteStatus({
    required this.userId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [userId, serviceId];
}

class RefreshFavorites extends FavoritesEvent {
  final String userId;

  const RefreshFavorites(this.userId);

  @override
  List<Object?> get props => [userId];
}