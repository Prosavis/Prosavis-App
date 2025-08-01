import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_entity.dart';

class SearchState extends Equatable {
  final List<String> recentSearches;
  final bool isRecentSearchesVisible;
  final bool isLoading;
  final List<ServiceEntity> searchResults;
  final String? errorMessage;
  final bool hasSearched;

  const SearchState({
    this.recentSearches = const [],
    this.isRecentSearchesVisible = false,
    this.isLoading = false,
    this.searchResults = const [],
    this.errorMessage,
    this.hasSearched = false,
  });

  SearchState copyWith({
    List<String>? recentSearches,
    bool? isRecentSearchesVisible,
    bool? isLoading,
    List<ServiceEntity>? searchResults,
    String? errorMessage,
    bool? hasSearched,
    bool clearError = false,
  }) {
    return SearchState(
      recentSearches: recentSearches ?? this.recentSearches,
      isRecentSearchesVisible: isRecentSearchesVisible ?? this.isRecentSearchesVisible,
      isLoading: isLoading ?? this.isLoading,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }

  @override
  List<Object?> get props => [
        recentSearches,
        isRecentSearchesVisible,
        isLoading,
        searchResults,
        errorMessage,
        hasSearched,
      ];
}