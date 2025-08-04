import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/usecases/auth/sign_in_with_mfa_usecase.dart';
import '../../../core/injection/injection_container.dart';
import 'mfa_resolver_dialog.dart';

/// Ejemplo de página de login con soporte MFA
/// Muestra cómo integrar MFA en tu flujo de autenticación existente
class LoginWithMFAExample extends StatefulWidget {
  const LoginWithMFAExample({super.key});

  @override
  State<LoginWithMFAExample> createState() => _LoginWithMFAExampleState();
}

class _LoginWithMFAExampleState extends State<LoginWithMFAExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _signInWithMFAUseCase = sl<SignInWithMFAUseCase>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de Sesión con MFA'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo o título
              Icon(
                Icons.security,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),
              Text(
                'Iniciar Sesión',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Accede a tu cuenta protegida',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu email';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón de inicio de sesión
              ElevatedButton(
                onPressed: _isLoading ? null : _signInWithMFA,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              // Mensaje de error
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Información sobre MFA
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Autenticación de Dos Factores',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Si tu cuenta tiene habilitada la autenticación de dos factores, '
                      'se te pedirá un código de verificación adicional después de '
                      'ingresar tu email y contraseña.',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithMFA() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Intentar iniciar sesión con soporte MFA
      final result = await _signInWithMFAUseCase.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      switch (result) {
        case SignInMFASuccess(:final user):
          // Inicio de sesión exitoso sin MFA
          _handleSuccessfulLogin(user.email);
          break;

        case SignInMFARequired(:final resolver):
          // MFA requerido - mostrar dialog de resolución
          _handleMFARequired(resolver);
          break;

        case SignInMFAError(:final message):
          // Error en el inicio de sesión
          setState(() {
            _errorMessage = message;
            _isLoading = false;
          });
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleSuccessfulLogin(String email) {
    setState(() {
      _isLoading = false;
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Bienvenido de vuelta, $email'),
        backgroundColor: Colors.green,
      ),
    );

    // Navegar a la pantalla principal
    // Navigator.pushReplacementNamed(context, '/home');
  }

  void _handleMFARequired(MultiFactorResolver resolver) {
    setState(() {
      _isLoading = false;
    });

    // Mostrar dialog de resolución MFA
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MFAResolverDialog(
        resolver: resolver,
        onMFAResolved: (email) {
          if (email != null) {
            // MFA resuelto exitosamente
            _handleSuccessfulLogin(email);
          } else {
            // MFA cancelado
            setState(() {
              _errorMessage = 'Verificación cancelada';
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// Widget de ejemplo para mostrar cómo navegar a la configuración MFA
class MFASettingsButton extends StatelessWidget {
  const MFASettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.security, color: Colors.orange),
        title: const Text('Autenticación de Dos Factores'),
        subtitle: const Text('Configura seguridad adicional para tu cuenta'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const MFASetupPage(),
          //   ),
          // );
          
          // Por ahora, mostrar un diálogo informativo
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Configuración MFA'),
              content: const Text(
                'Aquí puedes configurar la autenticación de dos factores '
                'para proteger tu cuenta con un código SMS adicional.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigator.pushNamed(context, '/mfa-setup');
                  },
                  child: const Text('Configurar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}