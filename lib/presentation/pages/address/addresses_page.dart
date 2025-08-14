import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../../../core/themes/app_theme.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_event.dart';
import '../../blocs/address/address_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../domain/entities/saved_address_entity.dart';
import '../../../core/utils/location_utils.dart';

class AddressesPage extends StatefulWidget {
  final String userId;
  const AddressesPage({super.key, required this.userId});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _attemptedImport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis direcciones'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openAdd(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: const Text('Agregar nueva dirección'),
            ),
          ),
        ),
      ),
      body: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) async {
          if (state is AddressLoaded && state.addresses.isEmpty && !_attemptedImport) {
            _attemptedImport = true;
            await _tryImportFromHome(context);
          }
        },
        builder: (context, state) {
          if (state is AddressInitial) {
            context.read<AddressBloc>().add(LoadAddresses(widget.userId));
          }
          if (state is AddressLoading || state is AddressInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AddressError) {
            return _ErrorState(
              message: state.message,
              onAdd: () => _openAdd(context),
            );
          }
          if (state is AddressLoaded) {
            final addresses = state.addresses;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // Dirección actual por GPS como opción rápida
                _CurrentLocationTile(
                  onUse: (addr) {
                    context.read<AddressBloc>().add(SetActiveAddressLocal(addr));
                  },
                ),
                const SizedBox(height: 16),
                if (addresses.isEmpty)
                  _EmptyState(onAdd: () => _openAdd(context))
                else ...[
                  Text('Guardadas', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...List.generate(addresses.length, (i) {
                    final a = addresses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AddressTile(
                        address: a,
                        isActive: state.active?.id == a.id,
                        onEdit: () => _openEdit(context, a),
                        onDelete: () => context
                            .read<AddressBloc>()
                            .add(DeleteAddress(widget.userId, a.id)),
                        onSetDefault: () => context
                            .read<AddressBloc>()
                            .add(SetDefaultAddress(widget.userId, a.id)),
                        onMore: () => _showOptionsSheet(context, a),
                      ),
                    );
                  })
                ]
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _tryImportFromHome(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final homeLocation = authState.user.location;
    if (homeLocation == null || homeLocation.trim().isEmpty) return;

    try {
      final results = await locationFromAddress(homeLocation);
      if (results.isEmpty) return;
      final loc = results.first;
      final now = DateTime.now();
      final entity = SavedAddressEntity(
        id: '',
        userId: widget.userId,
        label: 'Principal',
        addressLine: homeLocation,
        latitude: loc.latitude,
        longitude: loc.longitude,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );
      context.read<AddressBloc>().add(AddAddress(entity));
    } catch (_) {
      // no-op si falla el geocoding
    }
  }

  void _openAdd(BuildContext context) {
    context.push('/addresses/add', extra: {'userId': widget.userId});
  }

  void _openEdit(BuildContext context, SavedAddressEntity a) {
    context.push('/addresses/edit', extra: a);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.location_on, size: 56, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text('Aún no tienes direcciones', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Agrega tu Casa, Trabajo u otros lugares frecuentes.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAdd, child: const Text('Agregar dirección')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onAdd;
  const _ErrorState({required this.message, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.error, size: 56, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAdd, child: const Text('Agregar dirección')),
          ],
        ),
      ),
    );
  }
}

void _showOptionsSheet(BuildContext context, SavedAddressEntity address) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Más opciones', style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('¿Qué quieres hacer con esta dirección?',
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.getContainerColor(ctx),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Symbols.location_on),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.label, style: Theme.of(ctx).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(address.addressLine, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Symbols.edit),
                title: const Text('Editar dirección'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/addresses/edit', extra: address);
                },
              ),
              ListTile(
                leading: const Icon(Symbols.push_pin),
                title: const Text('Establecer como predeterminada'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<AddressBloc>().add(SetDefaultAddress(address.userId, address.id));
                },
              ),
              ListTile(
                leading: const Icon(Symbols.delete),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<AddressBloc>().add(DeleteAddress(address.userId, address.id));
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );
}

class _CurrentLocationTile extends StatefulWidget {
  final void Function(SavedAddressEntity) onUse;
  const _CurrentLocationTile({required this.onUse});

  @override
  State<_CurrentLocationTile> createState() => _CurrentLocationTileState();
}

class _CurrentLocationTileState extends State<_CurrentLocationTile> {
  String? _address;
  double? _lat;
  double? _lng;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final details = await LocationUtils.getCurrentLocationDetails();
      if (!mounted) return;
      setState(() {
        _address = details?['address'] as String?;
        _lat = (details?['latitude'] as num?)?.toDouble();
        _lng = (details?['longitude'] as num?)?.toDouble();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: ListTile(
        leading: const Icon(Symbols.my_location, color: AppTheme.accentColor),
        title: Text('Usar mi ubicación actual', style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          _loading ? 'Obteniendo ubicación…' : (_address ?? 'No disponible'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: (_lat != null && _lng != null && !_loading)
                  ? () async {
                      final now = DateTime.now();
                      widget.onUse(
                        SavedAddressEntity(
                          id: '',
                          userId: '',
                          label: 'Actual',
                          addressLine: _address ?? 'Ubicación actual',
                          latitude: _lat!,
                          longitude: _lng!,
                          isDefault: false,
                          createdAt: now,
                          updatedAt: now,
                        ),
                      );
                    }
                  : null,
              child: const Text('Usar'),
            ),
            ElevatedButton(
              onPressed: (_lat != null && _lng != null && !_loading)
                  ? () async {
                      // Abrir el editor precargado para permitir guardar
                      final now = DateTime.now();
                      final entity = SavedAddressEntity(
                        id: '',
                        userId: '',
                        label: 'Casa',
                        addressLine: _address ?? 'Ubicación actual',
                        latitude: _lat!,
                        longitude: _lng!,
                        isDefault: true,
                        createdAt: now,
                        updatedAt: now,
                      );
                      if (!mounted) return;
                      context.push('/addresses/edit', extra: entity);
                    }
                  : null,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final SavedAddressEntity address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final bool isActive;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.isActive,
    this.onMore,
  });
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                address.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (address.isDefault)
              const Chip(label: Text('Predeterminada')),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(address.addressLine, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        leading: Icon(
          isActive ? Symbols.radio_button_checked : Symbols.radio_button_unchecked,
          color: isActive ? AppTheme.primaryColor : AppTheme.getTextTertiary(context),
        ),
        trailing: IconButton(
          icon: const Icon(Symbols.more_horiz),
          onPressed: onMore ?? onEdit,
        ),
      ),
    );
  }
}


