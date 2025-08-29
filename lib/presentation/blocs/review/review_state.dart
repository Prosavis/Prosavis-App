import 'package:equatable/equatable.dart';
import '../../../domain/entities/review_entity.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewsLoaded extends ReviewState {
  final List<ReviewEntity> reviews;
  final String serviceId;

  const ReviewsLoaded({
    required this.reviews,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [reviews, serviceId];

  ReviewsLoaded copyWith({
    List<ReviewEntity>? reviews,
    String? serviceId,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      serviceId: serviceId ?? this.serviceId,
    );
  }
}

class ReviewActionLoading extends ReviewState {
  final String action; // 'creating', 'updating', 'deleting'

  const ReviewActionLoading(this.action);

  @override
  List<Object?> get props => [action];
}

class ReviewActionSuccess extends ReviewState {
  final String message;
  final String action;

  const ReviewActionSuccess({
    required this.message,
    required this.action,
  });

  @override
  List<Object?> get props => [message, action];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object?> get props => [message];
}
