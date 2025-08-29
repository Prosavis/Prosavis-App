import 'package:equatable/equatable.dart';
import '../../../domain/entities/review_entity.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadServiceReviews extends ReviewEvent {
  final String serviceId;
  final int limit;

  const LoadServiceReviews({
    required this.serviceId,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [serviceId, limit];
}

class CreateReview extends ReviewEvent {
  final ReviewEntity review;

  const CreateReview(this.review);

  @override
  List<Object?> get props => [review];
}

class UpdateReview extends ReviewEvent {
  final ReviewEntity review;

  const UpdateReview(this.review);

  @override
  List<Object?> get props => [review];
}

class DeleteReview extends ReviewEvent {
  final String reviewId;
  final String serviceId;

  const DeleteReview({
    required this.reviewId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [reviewId, serviceId];
}

class RefreshReviews extends ReviewEvent {
  final String serviceId;

  const RefreshReviews(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}
