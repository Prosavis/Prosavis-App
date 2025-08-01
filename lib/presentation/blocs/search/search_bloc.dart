import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/usecases/services/search_services_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchServicesUseCase _searchServicesUseCase;
  static const int _maxRecentSearches = 5;

  SearchBloc(this._searchServicesUseCase) : super(const SearchState()) {
    on<LoadRecentSearches>(_onLoadRecentSearches);
    on<AddRecentSearch>(_onAddRecentSearch);
    on<RemoveRecentSearch>(_onRemoveRecentSearch);
    on<ClearAllRecentSearches>(_onClearAllRecentSearches);
    on<ToggleRecentSearchesVisibility>(_onToggleRecentSearchesVisibility);
    on<SearchServices>(_onSearchServices);
    on<ClearSearchResults>(_onClearSearchResults);
  }

  Future<void> _onLoadRecentSearches(
    LoadRecentSearches event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSearchesJson = prefs.getStringList(AppConstants.recentSearchesKey) ?? [];
      
      final recentSearches = recentSearchesJson.cast<String>();
      
      emit(state.copyWith(
        recentSearches: recentSearches,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        recentSearches: [],
        isLoading: false,
      ));
    }
  }

  Future<void> _onAddRecentSearch(
    AddRecentSearch event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;

    final updatedSearches = List<String>.from(state.recentSearches);
    
    // Remover si ya existe
    updatedSearches.remove(event.query.trim());
    
    // Agregar al inicio
    updatedSearches.insert(0, event.query.trim());
    
    // Mantener solo los últimos _maxRecentSearches
    if (updatedSearches.length > _maxRecentSearches) {
      updatedSearches.removeRange(_maxRecentSearches, updatedSearches.length);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(AppConstants.recentSearchesKey, updatedSearches);
      
      emit(state.copyWith(recentSearches: updatedSearches));
    } catch (e) {
      // Si falla el guardado, mantener el estado actual
    }
  }

  Future<void> _onRemoveRecentSearch(
    RemoveRecentSearch event,
    Emitter<SearchState> emit,
  ) async {
    final updatedSearches = List<String>.from(state.recentSearches);
    updatedSearches.remove(event.query);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(AppConstants.recentSearchesKey, updatedSearches);
      
      emit(state.copyWith(recentSearches: updatedSearches));
    } catch (e) {
      // Si falla el guardado, mantener el estado actual
    }
  }

  Future<void> _onClearAllRecentSearches(
    ClearAllRecentSearches event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.recentSearchesKey);
      
      emit(state.copyWith(recentSearches: []));
    } catch (e) {
      // Si falla el guardado, mantener el estado actual
    }
  }

  void _onToggleRecentSearchesVisibility(
    ToggleRecentSearchesVisibility event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(
      isRecentSearchesVisible: !state.isRecentSearchesVisible,
    ));
  }

  Future<void> _onSearchServices(
    SearchServices event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      final services = await _searchServicesUseCase(
        SearchServicesParams(
          query: event.query,
          category: event.category,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
          priceType: event.priceType,
        ),
      );

      emit(state.copyWith(
        isLoading: false,
        searchResults: services,
        hasSearched: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error al buscar servicios: ${e.toString()}',
        hasSearched: true,
      ));
    }
  }

  void _onClearSearchResults(
    ClearSearchResults event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(
      searchResults: [],
      hasSearched: false,
      clearError: true,
    ));
  }
}