import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/address/address_event.dart';
import '../../blocs/address/address_state.dart';
import '../../../domain/entities/saved_address_entity.dart';
import '../../../domain/repositories/address_repository.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository repository;
  AddressBloc({required this.repository}) : super(AddressInitial()) {
    on<LoadAddresses>(_onLoad);
    on<AddAddress>(_onAdd);
    on<UpdateAddress>(_onUpdate);
    on<DeleteAddress>(_onDelete);
    on<SetDefaultAddress>(_onSetDefault);
  }

  Future<void> _onLoad(LoadAddresses event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      final list = await repository.getUserAddresses(event.userId);
      final active = list.firstWhere((e) => e.isDefault, orElse: () => list.isNotEmpty ? list.first : _empty());
      emit(AddressLoaded(addresses: list, active: list.isNotEmpty ? active : null));
    } catch (e) {
      emit(AddressError('No se pudieron cargar las direcciones'));
    }
  }

  Future<void> _onAdd(AddAddress event, Emitter<AddressState> emit) async {
    try {
      final current = state is AddressLoaded ? (state as AddressLoaded) : null;
      final address = event.address.id.isEmpty
          ? event.address.copyWith(id: const Uuid().v4(), createdAt: DateTime.now(), updatedAt: DateTime.now())
          : event.address.copyWith(updatedAt: DateTime.now());
      await repository.addAddress(address);
      if (current != null) {
        final list = List<SavedAddressEntity>.from(current.addresses)..insert(0, address);
        emit(current.copyWith(addresses: list, active: address.isDefault ? address : current.active));
      }
    } catch (_) {
      emit(AddressError('No se pudo agregar la dirección'));
    }
  }

  Future<void> _onUpdate(UpdateAddress event, Emitter<AddressState> emit) async {
    try {
      final updated = event.address.copyWith(updatedAt: DateTime.now());
      await repository.updateAddress(updated);
      if (state is AddressLoaded) {
        final s = state as AddressLoaded;
        final list = s.addresses.map((e) => e.id == updated.id ? updated : e).toList();
        emit(s.copyWith(addresses: list, active: updated.isDefault ? updated : s.active));
      }
    } catch (_) {
      emit(AddressError('No se pudo actualizar la dirección'));
    }
  }

  Future<void> _onDelete(DeleteAddress event, Emitter<AddressState> emit) async {
    try {
      await repository.deleteAddress(event.userId, event.addressId);
      if (state is AddressLoaded) {
        final s = state as AddressLoaded;
        final list = s.addresses.where((e) => e.id != event.addressId).toList();
        final active = s.active?.id == event.addressId ? (list.isNotEmpty ? list.first : null) : s.active;
        emit(s.copyWith(addresses: list, active: active));
      }
    } catch (_) {
      emit(AddressError('No se pudo eliminar la dirección'));
    }
  }

  Future<void> _onSetDefault(SetDefaultAddress event, Emitter<AddressState> emit) async {
    try {
      await repository.setDefaultAddress(event.userId, event.addressId);
      if (state is AddressLoaded) {
        final s = state as AddressLoaded;
        final list = s.addresses
            .map((e) => e.copyWith(isDefault: e.id == event.addressId))
            .toList();
        final active = list.firstWhere((e) => e.isDefault, orElse: () => list.first);
        emit(s.copyWith(addresses: list, active: active));
      }
    } catch (_) {
      emit(AddressError('No se pudo establecer como predeterminada'));
    }
  }

  SavedAddressEntity _empty() => SavedAddressEntity(
        id: '',
        userId: '',
        label: '',
        addressLine: '',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}


