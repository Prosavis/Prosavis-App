import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/usecases/auth/enroll_mfa_usecase.dart';
import '../../../core/injection/injection_container.dart';

class MFASetupPage extends StatefulWidget {
  const MFASetupPage({super.key});

  @override
  State<MFASetupPage> createState() => _MFASetupPageState();
}

class _MFASetupPageState extends State<MFASetupPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _enrollMFAUseCase = sl<EnrollMFAUseCase>();
  
  String? _verificationId;
  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Autenticación de Dos Factores'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado actual de MFA
            _buildMFAStatus(),
            const SizedBox(height: 24),
            
            // Formulario de inscripción
            if (!_enrollMFAUseCase.hasMultiFactorEnabled()) ...[
              _buildEnrollmentForm(),
            ],
            
            // Lista de factores inscritos
            if (_enrollMFAUseCase.hasMultiFactorEnabled()) ...[
              _buildEnrolledFactorsList(),
            ],
            
            // Mensajes de error
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMFAStatus() {
    final hasMultiFactor = _enrollMFAUseCase.hasMultiFactorEnabled();
    final factors = _enrollMFAUseCase.getEnrolledFactors();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasMultiFactor ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: hasMultiFactor ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasMultiFactor ? Icons.security : Icons.warning,
                color: hasMultiFactor ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                hasMultiFactor ? 'Protección activa' : 'Sin protección adicional',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasMultiFactor ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasMultiFactor
                ? 'Tu cuenta está protegida con ${factors.length} factor(es) adicional(es)'
                : 'Configura la autenticación de dos factores para mayor seguridad',
            style: TextStyle(
              color: hasMultiFactor ? Colors.green.shade600 : Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Configurar segundo factor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (!_isCodeSent) ...[
          // Paso 1: Ingresar número de teléfono
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Número de teléfono',
              hintText: '+57 300 123 4567',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendVerificationCode,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Enviar código de verificación'),
          ),
        ] else ...[
          // Paso 2: Ingresar código y nombre
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código de verificación',
              hintText: '123456',
              prefixIcon: Icon(Icons.sms),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre para este dispositivo',
              hintText: 'Mi teléfono principal',
              prefixIcon: Icon(Icons.phone_android),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _cancelEnrollment,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeEnrollment,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEnrolledFactorsList() {
    final factors = _enrollMFAUseCase.getEnrolledFactors();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Factores configurados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...factors.map((factor) => _buildFactorTile(factor)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addAnotherFactor,
          icon: const Icon(Icons.add),
          label: const Text('Agregar otro factor'),
        ),
      ],
    );
  }

  Widget _buildFactorTile(MultiFactorInfo factor) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.phone_android),
        title: Text(factor.displayName ?? 'Factor de autenticación'),
        subtitle: factor is PhoneMultiFactorInfo
            ? Text('SMS: ${factor.phoneNumber}')
            : Text('Inscrito: ${factor.enrollmentTimestamp}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmUnenrollFactor(factor),
        ),
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa un número de teléfono';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _enrollMFAUseCase.startEnrollment(_phoneController.text.trim());
      setState(() {
        _isCodeSent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al enviar código: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeEnrollment() async {
    if (_codeController.text.trim().isEmpty || _displayNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _enrollMFAUseCase.completeEnrollment(
        _verificationId!,
        _codeController.text.trim(),
        _displayNameController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Segundo factor configurado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isCodeSent = false;
          _isLoading = false;
          _phoneController.clear();
          _codeController.clear();
          _displayNameController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al confirmar código: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _cancelEnrollment() {
    setState(() {
      _isCodeSent = false;
      _phoneController.clear();
      _codeController.clear();
      _displayNameController.clear();
      _errorMessage = null;
    });
  }

  void _addAnotherFactor() {
    setState(() {
      _isCodeSent = false;
      _phoneController.clear();
      _codeController.clear();
      _displayNameController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _confirmUnenrollFactor(MultiFactorInfo factor) async {
    final shouldUnenroll = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${factor.displayName}"?\n\n'
          'Esto reducirá la seguridad de tu cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldUnenroll == true) {
      try {
        await _enrollMFAUseCase.unenrollFactor(factor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factor eliminado exitosamente'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {}); // Refresh the UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar factor: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
}