import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/location_utils.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_event.dart';
import '../../../domain/entities/saved_address_entity.dart';

class EditAddressPage extends StatefulWidget {
  final String userId;
  final SavedAddressEntity? initial;
  const EditAddressPage({super.key, required this.userId, this.initial});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _addressLine;
  late final TextEditingController _details;
  late final TextEditingController _building;
  double? _lat;
  double? _lng;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initial?.label ?? '');
    _addressLine = TextEditingController(text: widget.initial?.addressLine ?? '');
    _details = TextEditingController(text: widget.initial?.details ?? '');
    _building = TextEditingController(text: widget.initial?.buildingName ?? '');
    _lat = widget.initial?.latitude;
    _lng = widget.initial?.longitude;
    _isDefault = widget.initial?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _addressLine.dispose();
    _details.dispose();
    _building.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Agregar dirección' : 'Editar dirección'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Etiqueta (ej: Casa, Trabajo)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressLine,
              decoration: const InputDecoration(hintText: 'KR 8B # 1 - 32, Pereira', labelText: 'Dirección completa'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _details,
                    decoration: const InputDecoration(labelText: 'Detalles (apto, referencias)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _building,
                    decoration: const InputDecoration(labelText: 'Edificio/Condominio'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.getContainerColor(context),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _lat == null ? 'Selecciona ubicación en el mapa' : 'Ubicación seleccionada ($_lat, $_lng)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickOnMap,
                        icon: const Icon(Symbols.map),
                        label: const Text('Elegir en mapa'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Symbols.my_location),
                        label: const Text('Usar GPS'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Establecer como predeterminada'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final details = await LocationUtils.getCurrentLocationDetails();
    if (!mounted || details == null) return;
    setState(() {
      _lat = details['latitude'] as double?;
      _lng = details['longitude'] as double?;
      if ((details['address'] as String?)?.isNotEmpty == true) {
        _addressLine.text = details['address'] as String;
      }
    });
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.pushNamed(context, '/addresses/map');
    if (!mounted || result == null) return;
    final map = result as Map<String, dynamic>;
    setState(() {
      _lat = map['latitude'] as double?;
      _lng = map['longitude'] as double?;
      final addr = map['address'] as String?;
      if (addr != null && addr.isNotEmpty) {
        _addressLine.text = addr;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una ubicación válida')));
      return;
    }

    final now = DateTime.now();
    final entity = SavedAddressEntity(
      id: widget.initial?.id ?? '',
      userId: widget.userId,
      label: _label.text.trim(),
      addressLine: _addressLine.text.trim(),
      latitude: _lat!,
      longitude: _lng!,
      details: _details.text.trim().isEmpty ? null : _details.text.trim(),
      buildingName: _building.text.trim().isEmpty ? null : _building.text.trim(),
      isDefault: _isDefault,
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.initial == null) {
      context.read<AddressBloc>().add(AddAddress(entity));
    } else {
      context.read<AddressBloc>().add(UpdateAddress(entity));
    }
    Navigator.pop(context);
  }
}


