import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/injection/injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/favorites/favorites_event.dart';
import '../../blocs/favorites/favorites_state.dart';

import '../../widgets/common/service_card.dart';

class SavedPage extends StatefulWidget {
  final VoidCallback? onExploreServicesTapped;
  
  const SavedPage({super.key, this.onExploreServicesTapped});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    if (authState is AuthAuthenticated) {
                      return BlocProvider(
                        create: (context) => sl<FavoritesBloc>()
                          ..add(LoadUserFavorites(authState.user.id)),
                        child: _buildFavoritesContent(authState.user.id),
                      );
                    } else {
                      return const LoginRequiredWidget(
                        title: 'Inicia sesión para ver tus favoritos',
                        subtitle: 'Necesitas tener una cuenta para guardar servicios favoritos.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesContent(String userId) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (state is FavoritesError) {
          return _buildErrorState(state.message, userId);
        }
        
        if (state is FavoritesLoaded) {
          if (state.favorites.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildFavoritesList(state, userId);
        }
        
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildFavoritesList(FavoritesLoaded state, String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FavoritesBloc>().add(RefreshFavorites(userId));
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Symbols.favorite,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.favorites.length} servicio${state.favorites.length != 1 ? 's' : ''} guardado${state.favorites.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: state.favorites.length,
                itemBuilder: (context, index) {
                  final service = state.favorites[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ServiceCard(
                      service: service,
                      showFavoriteButton: true,
                      isFavorite: true,
                      onFavoriteToggle: () {
                        context.read<FavoritesBloc>().add(
                          RemoveFromFavorites(
                            userId: userId,
                            serviceId: service.id,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.favorite_border,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes favoritos aún',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Explora servicios y guarda tus favoritos tocando el ícono de corazón. Aparecerán aquí para acceso rápido.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onExploreServicesTapped,
              icon: const Icon(Symbols.search),
              label: const Text('Explorar servicios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Symbols.error,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar favoritos',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FavoritesBloc>().add(LoadUserFavorites(userId));
              },
              icon: const Icon(Symbols.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Text(
        'Favoritos',
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.getTextPrimary(context),
        ),
      ),
    );
  }
}