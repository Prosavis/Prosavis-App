import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/coming_soon_widget.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

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
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      return const ComingSoonWidget(
                        title: 'Coming Soon',
                        subtitle: 'Los favoritos e historial estarán disponibles pronto. Podrás guardar y revisar todos tus servicios favoritos.',
                        emoji: '❤️',
                        buttonText: 'Entendido',
                      );
                    } else {
                      return const LoginRequiredWidget(
                        title: 'Inicia sesión para ver tus favoritos',
                        subtitle: 'Necesitas tener una cuenta para guardar servicios favoritos y ver tu historial.',
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