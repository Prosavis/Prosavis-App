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
  final double? minPrice;
  final double? maxPrice;
  final String? priceType;

  const SearchServices({
    this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.priceType,
  });

  @override
  List<Object?> get props => [query, category, minPrice, maxPrice, priceType];
}

class ClearSearchResults extends SearchEvent {}