import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<ServiceEntity> featuredServices;
  final List<ServiceEntity> nearbyServices;

  const HomeLoaded({
    required this.featuredServices,
    required this.nearbyServices,
  });

  @override
  List<Object> get props => [featuredServices, nearbyServices];

  HomeLoaded copyWith({
    List<ServiceEntity>? featuredServices,
    List<ServiceEntity>? nearbyServices,
  }) {
    return HomeLoaded(
      featuredServices: featuredServices ?? this.featuredServices,
      nearbyServices: nearbyServices ?? this.nearbyServices,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}