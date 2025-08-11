import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSignUp = false;
  bool _isPhoneLogin = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Symbols.arrow_back,
            color: AppTheme.getTextPrimary(context),
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Iniciar Sesión',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthPhoneCodeSent) {
            context.push('/auth/verify-phone', extra: {
              'verificationId': state.verificationId,
              'phoneNumber': state.phoneNumber,
            });
          } else if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email de recuperación enviado a ${state.email}'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      // Header con logo compacto
                      _buildCompactHeader(),
                      
                      const SizedBox(height: 32),
                      
                      // Formulario principal
                      _buildLoginForm(state),
                      
                      const SizedBox(height: 24),
                      
                      // Divisor con texto
                      _buildDivider(),
                      
                      const SizedBox(height: 24),
                      
                      // Google Sign In (Recomendado)
                      _buildGoogleSignInButton(state),
                      
                      const SizedBox(height: 32),
                      
                      // Enlaces adicionales
                      _buildAdditionalLinks(),
                      
                      const SizedBox(height: 24),
                      
                      // Terms and Privacy
                      _buildTermsAndPrivacy(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Symbols.handyman,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            Text(
              'Conectando servicios de calidad',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState state) {
    final isLoading = state is AuthLoading;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del formulario
          Text(
            _isPhoneLogin ? 'Iniciar sesión con teléfono' : 
            _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimary(context),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Selector de método de autenticación
          if (!_isPhoneLogin) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMethodButton(
                    'Email',
                    Symbols.email,
                    !_isPhoneLogin,
                    () => setState(() => _isPhoneLogin = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMethodButton(
                    'Teléfono',
                    Symbols.phone,
                    _isPhoneLogin,
                    () => setState(() => _isPhoneLogin = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          
          // Campos de formulario
          if (_isPhoneLogin) ...[
            _buildPhoneForm(isLoading),
          ] else ...[
            _buildEmailForm(isLoading),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodButton(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkSurfaceVariant.withValues(alpha: 0.6)
                      : AppTheme.primaryColor.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBorder
                        : Colors.grey.shade300),
                width: 1,
              ),
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.primaryColor)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primaryColor)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isLoading) {
    return Form(
      key: _isSignUp ? _signUpFormKey : _loginFormKey,
      child: Column(
        children: [
        // Campo de nombre (solo en registro)
        if (_isSignUp) ...[
          _buildTextField(
            controller: _nameController,
            label: 'Nombre completo',
            icon: Symbols.person,
            keyboardType: TextInputType.name,
            validator: Validators.validateName,
          ),
          const SizedBox(height: 16),
        ],
        
        // Campo de email
        _buildTextField(
          controller: _emailController,
          label: 'Correo electrónico',
          icon: Symbols.email,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        
        const SizedBox(height: 16),
        
        // Campo de contraseña
        _buildTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Symbols.lock,
          isPassword: true,
          obscureText: !_isPasswordVisible,
          validator: Validators.validatePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Symbols.visibility_off : Symbols.visibility,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        
        // Campo de confirmar contraseña (solo en registro)
        if (_isSignUp) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar contraseña',
            icon: Symbols.lock,
            isPassword: true,
            obscureText: !_isConfirmPasswordVisible,
            validator: (value) => Validators.validatePasswordConfirmation(value, _passwordController.text),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Symbols.visibility_off : Symbols.visibility,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
        ],
        
        // Enlace "Olvidé mi contraseña" (solo en login)
        if (!_isSignUp) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Olvidé mi contraseña',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Botón principal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleEmailAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        // Enlace para cambiar entre login y registro
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSignUp ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isSignUp ? 'Iniciar sesión' : 'Crear cuenta',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        children: [
        _buildTextField(
          controller: _phoneController,
          label: 'Número de celular (Colombia)',
          icon: Symbols.phone,
          keyboardType: TextInputType.phone,
          hintText: '300 123 4567',
          prefix: const Text('+57 ', style: TextStyle(fontWeight: FontWeight.bold)),
          validator: Validators.validatePhone,
          onChanged: (value) {
            // Formatear automáticamente mientras el usuario escribe
            final formatted = Validators.formatPhoneForDisplay(value);
            if (formatted != value) {
              _phoneController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
        ),
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handlePhoneAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Enviar código SMS',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Prefieres usar email?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isPhoneLogin = false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Cambiar a email',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? prefix,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: AppTheme.getTextTertiary(context)),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            prefix: prefix,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBorder
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurface
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'O continúa con',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(AuthState state) {
    final isLoading = state is AuthLoading;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                context.read<AuthBloc>().add(AuthSignInWithGoogleRequested());
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          side: BorderSide(color: AppTheme.getBorderColor(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/Google.svg.png',
                    height: 20,
                    width: 20,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Symbols.account_circle,
                        size: 20,
                        color: AppTheme.primaryColor,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continuar con Google',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdditionalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () {
            // Navegar a la página de ayuda
          },
          icon: Icon(
            Symbols.help,
            size: 18,
            color: AppTheme.getTextSecondary(context),
          ),
          label: Text(
            'Ayuda',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(width: 24),
        TextButton.icon(
          onPressed: () {
            // Navegar a soporte
          },
          icon: Icon(
            Symbols.support_agent,
            size: 18,
            color: AppTheme.getTextSecondary(context),
          ),
          label: Text(
            'Soporte',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        Text(
          'Al continuar, aceptas nuestros',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // Navegar a Términos de Servicio
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Términos de Servicio',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' y ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navegar a Política de Privacidad
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Política de Privacidad',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Métodos de manejo de eventos
  void _handleEmailAuth() {
    final formKey = _isSignUp ? _signUpFormKey : _loginFormKey;
    
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (_isSignUp) {
      context.read<AuthBloc>().add(AuthSignUpWithEmailRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      ));
    } else {
      context.read<AuthBloc>().add(AuthSignInWithEmailRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ));
    }
  }

  void _handlePhoneAuth() {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    // Formatear número colombiano con +57
    final formattedPhone = Validators.formatColombianPhone(_phoneController.text.trim());

    context.read<AuthBloc>().add(AuthSignInWithPhoneRequested(
      phoneNumber: formattedPhone,
    ));
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Recuperar contraseña',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                context.read<AuthBloc>().add(AuthPasswordResetRequested(
                  email: emailController.text.trim(),
                ));
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Enviar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 