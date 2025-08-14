import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecentSearches extends SearchEvent {}

class AddRecentSearch extends SearchEvent {
  final String query;

  const AddRecentSearch(this.query);

  @override
  List<Object> get props => [query];
}

class RemoveRecentSearch extends SearchEvent {
  final String query;

  const RemoveRecentSearch(this.query);

  @override
  List<Object> get props => [query];
}

class ClearAllRecentSearches extends SearchEvent {}

class ToggleRecentSearchesVisibility extends SearchEvent {}

class SearchServices extends SearchEvent {
  final String? query;
  final String? category;
  final List<String>? categories;
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;
  final double? minRating;
  final String? sortBy; // 'newest', 'priceLowToHigh', 'priceHighToLow', 'rating', 'distance'
  final double? radiusKm;
  final double? userLatitude;
  final double? userLongitude;

  const SearchServices({
    this.query,
    this.category,
    this.categories,
    this.minPrice,
    this.maxPrice,
    this.priceType,
    this.minRating,
    this.sortBy,
    this.radiusKm,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  List<Object?> get props => [
        query,
        category,
        categories,
        minPrice,
        maxPrice,
        priceType,
        minRating,
        sortBy,
        radiusKm,
        userLatitude,
        userLongitude,
      ];
}

class ClearSearchResults extends SearchEvent {}