import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../home/home_page.dart';
import '../saved/saved_page.dart';
import '../profile/profile_page.dart';
import '../services/service_creation_page.dart';
import '../../../domain/usecases/services/create_service_usecase.dart';
import '../../../core/injection/injection_container.dart' as di;


class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      HomePage(onProfileTapped: _goToProfile),
      ServiceCreationPage(createServiceUseCase: di.sl<CreateServiceUseCase>()),
      const SavedPage(),
      const ProfilePage(),
    ];
  }

  void _goToProfile() {
    _onItemTapped(3); // Índice 3 corresponde a ProfilePage
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
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
        onTap: _onItemTapped,
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