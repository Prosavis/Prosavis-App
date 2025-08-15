import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/address/address_event.dart';
import '../../blocs/address/address_state.dart';
import '../../../domain/entities/saved_address_entity.dart';
import '../../../domain/repositories/address_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/user_entity.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository repository;
  final FirestoreService _firestoreService = FirestoreService();
  
  AddressBloc({required this.repository}) : super(AddressInitial()) {
    on<LoadAddresses>(_onLoad);
    on<AddAddress>(_onAdd);
    on<UpdateAddress>(_onUpdate);
    on<DeleteAddress>(_onDelete);
    on<SetDefaultAddress>(_onSetDefault);
    on<SetActiveAddressLocal>(_onSetActiveLocal);
    on<SyncActiveAddressToProfile>(_onSyncToProfile);
  }

  Future<void> _onLoad(LoadAddresses event, Emitter<AddressState> emit) async {
    // Preservar la ubicación activa actual si existe y es temporal (GPS)
    SavedAddressEntity? currentActive;
    if (state is AddressLoaded) {
      final currentState = state as AddressLoaded;
      currentActive = currentState.active;
    }
    
    emit(AddressLoading());
    try {
      final list = await repository.getUserAddresses(event.userId);
      
      // Determinar dirección activa: priorizar GPS temporal si existe, sino usar guardada por defecto
      SavedAddressEntity? active;
      if (currentActive != null && currentActive.id == 'gps_current') {
        // Preservar ubicación GPS temporal
        active = currentActive;
      } else {
        // Usar dirección guardada por defecto
        active = list.firstWhere((e) => e.isDefault, orElse: () => list.isNotEmpty ? list.first : _empty());
        active = list.isNotEmpty ? active : null;
      }
      
      emit(AddressLoaded(addresses: list, active: active));
    } catch (e) {
      // Si hay error pero teníamos ubicación GPS, preservarla
      if (currentActive != null && currentActive.id == 'gps_current') {
        emit(AddressLoaded(addresses: const [], active: currentActive));
      } else {
        emit(AddressError('No se pudieron cargar las direcciones'));
      }
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

  void _onSetActiveLocal(SetActiveAddressLocal event, Emitter<AddressState> emit) {
    if (state is AddressLoaded) {
      final s = state as AddressLoaded;
      emit(s.copyWith(active: event.address));
    } else {
      // Si no hay estado AddressLoaded, crear uno con lista vacía pero con ubicación activa
      emit(AddressLoaded(
        addresses: const [], 
        active: event.address,
      ));
    }
  }

  Future<void> _onSyncToProfile(SyncActiveAddressToProfile event, Emitter<AddressState> emit) async {
    try {
      // Obtener el usuario actual
      final currentUser = await _firestoreService.getUserById(event.userId);
      if (currentUser == null) return;

      // Actualizar la ubicación del usuario con la dirección activa
      final updatedUser = UserEntity(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        photoUrl: currentUser.photoUrl,
        phoneNumber: currentUser.phoneNumber,
        bio: currentUser.bio,
        location: event.address.addressLine, // Sincronizar la dirección
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createOrUpdateUser(updatedUser);
      
      // El estado no cambia aquí, solo sincronizamos con el perfil
    } catch (e) {
      // Manejar error silenciosamente para no interrumpir la experiencia del usuario
      // En una implementación más robusta, podrías emitir un estado de error específico
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


