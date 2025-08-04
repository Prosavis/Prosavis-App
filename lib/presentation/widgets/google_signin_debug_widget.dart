import 'package:flutter/material.dart';
import '../../data/services/firebase_service.dart';
import '../../core/injection/injection_container.dart';

class GoogleSignInDebugWidget extends StatefulWidget {
  const GoogleSignInDebugWidget({super.key});

  @override
  State<GoogleSignInDebugWidget> createState() => _GoogleSignInDebugWidgetState();
}

class _GoogleSignInDebugWidgetState extends State<GoogleSignInDebugWidget> {
  final _firebaseService = sl<FirebaseService>();
  Map<String, dynamic>? _diagnosis;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.bug_report, color: Colors.orange),
        title: const Text('Diagnóstico Google Sign-In'),
        subtitle: const Text('Herramientas para diagnosticar problemas'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botones de diagnóstico
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _runDiagnosis,
                        icon: const Icon(Icons.search),
                        label: const Text('Diagnosticar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _clearCache,
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar Caché'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón de prueba
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Probar Google Sign-In'),
                ),
                
                // Loading indicator
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                
                // Resultados del diagnóstico
                if (_diagnosis != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Resultados del Diagnóstico:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._buildDiagnosisResults(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDiagnosisResults() {
    if (_diagnosis == null) return [];
    
    final results = <Widget>[];
    
    _diagnosis!.forEach((key, value) {
      IconData icon;
      Color color;
      
      if (key == 'status' && value == 'success') {
        icon = Icons.check_circle;
        color = Colors.green;
      } else if (key.contains('error') || (key == 'status' && value == 'error')) {
        icon = Icons.error;
        color = Colors.red;
      } else if (value == true) {
        icon = Icons.check;
        color = Colors.green;
      } else if (value == false) {
        icon = Icons.close;
        color = Colors.red;
      } else {
        icon = Icons.info;
        color = Colors.blue;
      }
      
      results.add(
        ListTile(
          dense: true,
          leading: Icon(icon, color: color, size: 20),
          title: Text(
            _formatKey(key),
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            value.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    });
    
    return results;
  }

  String _formatKey(String key) {
    // Convertir snake_case a formato legible
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isLoading = true;
      _diagnosis = null;
    });

    try {
      final diagnosis = await _firebaseService.diagnoseGoogleSignIn();
      setState(() {
        _diagnosis = diagnosis;
      });
      
      _showSnackBar(
        'Diagnóstico completado', 
        diagnosis['status'] == 'success' ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showSnackBar('Error en diagnóstico: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firebaseService.clearGoogleSignInCache();
      _showSnackBar('Caché limpiado exitosamente', Colors.green);
    } catch (e) {
      _showSnackBar('Error al limpiar caché: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      
      if (userCredential?.user != null) {
        _showSnackBar(
          'Google Sign-In exitoso: ${userCredential!.user!.email}',
          Colors.green,
        );
        
        // Actualizar diagnóstico después del éxito
        await _runDiagnosis();
      } else {
        _showSnackBar('Google Sign-In cancelado por el usuario', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error en Google Sign-In: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}