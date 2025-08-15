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
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // Siempre mostrar la UI, incluso si hay errores
          final addresses = (state is AddressLoaded) ? state.addresses : <SavedAddressEntity>[];
          
          return StretchingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                // Sección de ubicación GPS actual - siempre visible
                Text('Ubicación Actual', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _CurrentLocationTile(userId: widget.userId),
                const SizedBox(height: 24),
                
                // Sección de direcciones guardadas
                Text('Direcciones Guardadas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                
                if (addresses.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkSurface
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkBorder
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Symbols.add_location, size: 48, color: AppTheme.primaryColor),
                        const SizedBox(height: 12),
                        Text(
                          'Sin direcciones guardadas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega tu casa, trabajo u otros lugares que visites frecuentemente para acceso rápido.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...List.generate(addresses.length, (i) {
                    final a = addresses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AddressTile(
                        address: a,
                        isActive: (state is AddressLoaded) ? state.active?.id == a.id : false,
                        onEdit: () => _openEdit(context, a),
                        onDelete: () => context
                            .read<AddressBloc>()
                            .add(DeleteAddress(widget.userId, a.id)),
                        onSetDefault: () {
                          context.read<AddressBloc>().add(SetDefaultAddress(widget.userId, a.id));
                          // Sincronizar la dirección predeterminada con el perfil
                          context.read<AddressBloc>().add(SyncActiveAddressToProfile(widget.userId, a));
                        },
                        onMore: () => _showOptionsSheet(context, a),
                      ),
                    );
                  })
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _tryImportFromHome(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final homeLocation = authState.user.location;
    if (homeLocation == null || homeLocation.trim().isEmpty) return;

    // Capturar referencia al AddressBloc antes de operaciones asíncronas
    final addressBloc = context.read<AddressBloc>();

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
      
      // Verificar si el widget está montado antes de usar el bloc
      if (mounted) {
        addressBloc.add(AddAddress(entity));
      }
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
                  // Sincronizar la dirección predeterminada con el perfil
                  context.read<AddressBloc>().add(SyncActiveAddressToProfile(address.userId, address));
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

class _CurrentLocationTile extends StatelessWidget {
  final String userId;
  const _CurrentLocationTile({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, state) {
        // Cargar direcciones si no están cargadas
        if (state is AddressInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<AddressBloc>().add(LoadAddresses(userId));
            }
          });
        }
        // Obtener la ubicación activa del estado
        SavedAddressEntity? activeLocation;
        String displayAddress = 'Ubicación no disponible';
        bool hasLocation = false;
        bool isLoading = false;

        if (state is AddressLoading) {
          displayAddress = 'Obteniendo ubicación...';
          isLoading = true;
        } else if (state is AddressLoaded && state.active != null) {
          activeLocation = state.active;
          displayAddress = activeLocation!.addressLine;
          hasLocation = true;
        } else if (state is AddressInitial) {
          displayAddress = 'Configurando ubicación...';
          isLoading = true;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono naranja (mantener como está)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Symbols.my_location, 
                  color: AppTheme.accentColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Información de ubicación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usar mi ubicación actual',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isLoading) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            displayAddress,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.getTextSecondary(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Solo botón Guardar
              ElevatedButton(
                onPressed: hasLocation && activeLocation != null && !isLoading
                    ? () {
                        // Crear entidad para guardar con label por defecto
                        final entity = SavedAddressEntity(
                          id: '',
                          userId: userId,
                          label: 'Casa',
                          addressLine: activeLocation!.addressLine,
                          latitude: activeLocation.latitude,
                          longitude: activeLocation.longitude,
                          isDefault: true,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        context.push('/addresses/edit', extra: entity);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
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


