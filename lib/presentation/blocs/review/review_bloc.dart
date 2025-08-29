import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/review_repository.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;

  ReviewBloc(this._reviewRepository) : super(ReviewInitial()) {
    on<LoadServiceReviews>(_onLoadServiceReviews);
    on<CreateReview>(_onCreateReview);
    on<UpdateReview>(_onUpdateReview);
    on<DeleteReview>(_onDeleteReview);
    on<RefreshReviews>(_onRefreshReviews);
  }

  Future<void> _onLoadServiceReviews(
    LoadServiceReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());
    
    try {
      developer.log('📖 Cargando reseñas del servicio: ${event.serviceId}');
      
      final reviews = await _reviewRepository.getServiceReviews(
        event.serviceId,
        limit: event.limit,
      );
      
      emit(ReviewsLoaded(
        reviews: reviews,
        serviceId: event.serviceId,
      ));
      
      developer.log('✅ ${reviews.length} reseñas cargadas exitosamente');
    } catch (e) {
      developer.log('❌ Error al cargar reseñas: $e');
      emit(ReviewError('Error al cargar las reseñas: $e'));
    }
  }

  Future<void> _onCreateReview(
    CreateReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('creating'));
    
    try {
      developer.log('📝 Creando reseña para servicio: ${event.review.serviceId}');
      
      await _reviewRepository.createReview(event.review);
      
      emit(const ReviewActionSuccess(
        message: 'Reseña creada exitosamente',
        action: 'create',
      ));
      
      // Recargar las reseñas del servicio
      add(LoadServiceReviews(serviceId: event.review.serviceId));
      
      developer.log('✅ Reseña creada exitosamente');
    } catch (e) {
      developer.log('❌ Error al crear reseña: $e');
      emit(ReviewError('Error al crear la reseña: $e'));
    }
  }

  Future<void> _onUpdateReview(
    UpdateReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('updating'));
    
    try {
      developer.log('📝 Actualizando reseña: ${event.review.id}');
      
      await _reviewRepository.updateReview(event.review);
      
      emit(const ReviewActionSuccess(
        message: 'Reseña actualizada exitosamente',
        action: 'update',
      ));
      
      // Recargar las reseñas del servicio
      add(LoadServiceReviews(serviceId: event.review.serviceId));
      
      developer.log('✅ Reseña actualizada exitosamente');
    } catch (e) {
      developer.log('❌ Error al actualizar reseña: $e');
      emit(ReviewError('Error al actualizar la reseña: $e'));
    }
  }

  Future<void> _onDeleteReview(
    DeleteReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(const ReviewActionLoading('deleting'));
    
    try {
      developer.log('🗑️ Eliminando reseña: ${event.reviewId}');
      
      await _reviewRepository.deleteReview(event.reviewId, serviceId: event.serviceId);
      
      emit(const ReviewActionSuccess(
        message: 'Reseña eliminada exitosamente',
        action: 'delete',
      ));
      
      // Recargar las reseñas del servicio
      add(LoadServiceReviews(serviceId: event.serviceId));
      
      developer.log('✅ Reseña eliminada exitosamente');
    } catch (e) {
      developer.log('❌ Error al eliminar reseña: $e');
      emit(ReviewError('Error al eliminar la reseña: $e'));
    }
  }

  Future<void> _onRefreshReviews(
    RefreshReviews event,
    Emitter<ReviewState> emit,
  ) async {
    try {
      developer.log('🔄 Refrescando reseñas del servicio: ${event.serviceId}');
      
      final reviews = await _reviewRepository.getServiceReviews(event.serviceId);
      
      if (state is ReviewsLoaded) {
        final currentState = state as ReviewsLoaded;
        emit(currentState.copyWith(reviews: reviews));
      } else {
        emit(ReviewsLoaded(
          reviews: reviews,
          serviceId: event.serviceId,
        ));
      }
      
      developer.log('✅ Reseñas refrescadas exitosamente');
    } catch (e) {
      developer.log('❌ Error al refrescar reseñas: $e');
      emit(ReviewError('Error al refrescar las reseñas: $e'));
    }
  }
}
