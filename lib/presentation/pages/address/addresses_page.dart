import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/themes/app_theme.dart';
import '../../blocs/address/address_bloc.dart';
import '../../blocs/address/address_event.dart';
import '../../blocs/address/address_state.dart';
import '../../../domain/entities/saved_address_entity.dart';

class AddressesPage extends StatelessWidget {
  final String userId;
  const AddressesPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis direcciones'),
      ),
      body: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          if (state is AddressInitial) {
            context.read<AddressBloc>().add(LoadAddresses(userId));
          }
          if (state is AddressLoading || state is AddressInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AddressLoaded) {
            final addresses = state.addresses;
            if (addresses.isEmpty) {
              return _EmptyState(onAdd: () => _openAdd(context));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (ctx, i) {
                      final a = addresses[i];
                      return _AddressTile(
                        address: a,
                        isActive: state.active?.id == a.id,
                        onEdit: () => _openEdit(context, a),
                        onDelete: () => context
                            .read<AddressBloc>()
                            .add(DeleteAddress(userId, a.id)),
                        onSetDefault: () => context
                            .read<AddressBloc>()
                            .add(SetDefaultAddress(userId, a.id)),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: addresses.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openAdd(context),
                      child: const Text('Agregar nueva dirección'),
                    ),
                  ),
                )
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.pushNamed(context, '/addresses/add', arguments: {'userId': userId});
  }

  void _openEdit(BuildContext context, SavedAddressEntity a) {
    Navigator.pushNamed(context, '/addresses/edit', arguments: a);
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
  });

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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
              case 'default':
                onSetDefault();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'default', child: Text('Establecer predeterminada')),
            const PopupMenuItem(value: 'edit', child: Text('Editar dirección')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}


