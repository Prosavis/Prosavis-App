import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/usecases/auth/sign_in_with_mfa_usecase.dart';
import '../../../core/injection/injection_container.dart';

class MFAResolverDialog extends StatefulWidget {
  final MultiFactorResolver resolver;
  final Function(String?) onMFAResolved; // null si cancelado, email si exitoso

  const MFAResolverDialog({
    super.key,
    required this.resolver,
    required this.onMFAResolved,
  });

  @override
  State<MFAResolverDialog> createState() => _MFAResolverDialogState();
}

class _MFAResolverDialogState extends State<MFAResolverDialog> {
  final _codeController = TextEditingController();
  final _signInWithMFAUseCase = sl<SignInWithMFAUseCase>();
  
  String? _verificationId;
  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _errorMessage;
  int _selectedHintIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-seleccionar el primer factor si solo hay uno
    if (widget.resolver.hints.length == 1) {
      _sendMFACode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.orange),
          SizedBox(width: 8),
          Text('Verificación requerida'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tu cuenta está protegida con autenticación de dos factores. '
              'Selecciona un método de verificación:',
            ),
            const SizedBox(height: 16),
            
            // Selección de factor (si hay múltiples)
            if (widget.resolver.hints.length > 1 && !_isCodeSent) ...[
              _buildFactorSelection(),
              const SizedBox(height: 16),
            ],
            
            // Mostrar factor seleccionado si ya se envió el código
            if (_isCodeSent) ...[
              _buildSelectedFactorInfo(),
              const SizedBox(height: 16),
            ],
            
            // Campo de código SMS
            if (_isCodeSent) ...[
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
                onChanged: (value) {
                  // Auto-verificar cuando se complete el código
                  if (value.length == 6) {
                    _verifyMFACode();
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código de 6 dígitos enviado a tu teléfono.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            
            // Mensaje de error
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            widget.onMFAResolved(null); // Cancelado
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        if (!_isCodeSent) ...[
          ElevatedButton(
            onPressed: _isLoading ? null : _sendMFACode,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar código'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _isLoading || _codeController.text.length != 6 
                ? null 
                : _verifyMFACode,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verificar'),
          ),
        ],
      ],
    );
  }

  Widget _buildFactorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métodos disponibles:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...widget.resolver.hints.asMap().entries.map((entry) {
          final index = entry.key;
          final hint = entry.value;

          final isSelected = _selectedHintIndex == index;

          return ListTile(
            onTap: () {
              setState(() {
                _selectedHintIndex = index;
              });
            },
            leading: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(hint.displayName ?? 'Factor de autenticación'),
            subtitle: hint is PhoneMultiFactorInfo
                ? Text('SMS: ${hint.phoneNumber}')
                : const Text('Método de verificación'),
            dense: true,
            selected: isSelected,
            selectedColor: Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildSelectedFactorInfo() {
    final hint = widget.resolver.hints[_selectedHintIndex];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint.displayName ?? 'Factor de autenticación',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
                if (hint is PhoneMultiFactorInfo)
                  Text(
                    'Código enviado a ${hint.phoneNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMFACode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _verificationId = await _signInWithMFAUseCase.sendMFACode(
        widget.resolver,
        _selectedHintIndex,
      );
      
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

  Future<void> _verifyMFACode() async {
    if (_codeController.text.trim().length != 6) {
      setState(() {
        _errorMessage = 'El código debe tener 6 dígitos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _signInWithMFAUseCase.resolveMFA(
        widget.resolver,
        _verificationId!,
        _codeController.text.trim(),
      );

      if (user != null) {
        widget.onMFAResolved(user.email);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'Error al verificar el código';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Código incorrecto o expirado';
        _isLoading = false;
        _codeController.clear();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}