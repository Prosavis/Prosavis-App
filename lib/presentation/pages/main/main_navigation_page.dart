import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../home/home_page.dart';
import '../saved/saved_page.dart';
import '../profile/profile_page.dart';
import '../services/my_services_page.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/favorites/favorites_bloc.dart';
import '../../blocs/favorites/favorites_event.dart';
import '../../widgets/common/auth_required_dialog.dart';


class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  List<Widget>? _pages;

  @override
  bool get wantKeepAlive => true; // Mantener estado para evitar reconstrucciones

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      keepPage: true, // Optimización: mantener páginas en memoria
    );
  }

  // Lazy loading de las páginas para evitar problemas con GetIt
  List<Widget> get pages {
    _pages ??= [
      HomePage(onProfileTapped: _goToProfile),
      // Optimización: Crear páginas con AutomaticKeepAlive cuando sea necesario
      const KeepAlivePage(
        child: MyServicesPage(),
      ),
      SavedPage(onExploreServicesTapped: () => onItemTapped(0)),
      const ProfilePage(),
    ];
    return _pages!;
  }

  void _goToProfile() {
    onItemTapped(3); // Índice 3 corresponde a ProfilePage
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onItemTapped(int index) {
    // Verificar autenticación para pestañas protegidas
    if ((index == 1 || index == 2)) { // Ofrecer (1) y Favoritos (2)
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        _showAuthRequiredDialog(index);
        return;
      }
    }

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _dispatchTabRefreshIfNeeded(index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _dispatchTabRefreshIfNeeded(int index) {
    // 0: Inicio, 1: Ofrecer, 2: Favoritos, 3: Perfil
    if (index == 0) {
      // Refrescar Home al volver al tab
      context.read<HomeBloc>().add(RefreshHomeServices());
    } else if (index == 2) {
      // Refrescar Favoritos al volver al tab si hay usuario
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<FavoritesBloc>().add(RefreshFavorites(authState.user.id));
      }
    }
  }

  void _showAuthRequiredDialog(int attemptedIndex) {
    final String featureName = attemptedIndex == 1 ? 'ofrecer servicios' : 'favoritos';
    
    showDialog(
      context: context,
      builder: (context) => AuthRequiredDialog(
        title: 'Inicia Sesión',
        message: 'Para acceder a $featureName necesitas iniciar sesión en tu cuenta.',
        onLoginTapped: () {
          // Ir a la pestaña de perfil para iniciar sesión
          setState(() {
            _selectedIndex = 3;
          });
          _pageController.animateToPage(
            3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Optimización: Solo setState si el índice realmente cambió
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
            _dispatchTabRefreshIfNeeded(index);
          }
        },
        children: pages, // Usar el getter que maneja lazy loading
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textTertiary,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Symbols.home),
            activeIcon: Icon(Symbols.home, fill: 1),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.work),
            activeIcon: Icon(Symbols.work, fill: 1),
            label: 'Ofrecer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.favorite),
            activeIcon: Icon(Symbols.favorite, fill: 1),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.person),
            activeIcon: Icon(Symbols.person, fill: 1),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Widget optimizado que mantiene el estado de sus hijos
/// Previene reconstrucciones innecesarias de páginas complejas
class KeepAlivePage extends StatefulWidget {
  final Widget child;
  
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}