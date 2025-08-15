import 'package:equatable/equatable.dart';
import '../../../domain/entities/saved_address_entity.dart';

abstract class AddressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressEvent {
  final String userId;
  LoadAddresses(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AddAddress extends AddressEvent {
  final SavedAddressEntity address;
  AddAddress(this.address);
  @override
  List<Object?> get props => [address];
}

class UpdateAddress extends AddressEvent {
  final SavedAddressEntity address;
  UpdateAddress(this.address);
  @override
  List<Object?> get props => [address];
}

class DeleteAddress extends AddressEvent {
  final String userId;
  final String addressId;
  DeleteAddress(this.userId, this.addressId);
  @override
  List<Object?> get props => [userId, addressId];
}

class SetDefaultAddress extends AddressEvent {
  final String userId;
  final String addressId;
  SetDefaultAddress(this.userId, this.addressId);
  @override
  List<Object?> get props => [userId, addressId];
}

/// Establece una dirección activa solo en memoria (no persiste)
class SetActiveAddressLocal extends AddressEvent {
  final SavedAddressEntity address;
  SetActiveAddressLocal(this.address);
  @override
  List<Object?> get props => [address];
}

/// Sincroniza la dirección activa con el perfil del usuario en la base de datos
class SyncActiveAddressToProfile extends AddressEvent {
  final String userId;
  final SavedAddressEntity address;
  SyncActiveAddressToProfile(this.userId, this.address);
  @override
  List<Object?> get props => [userId, address];
}


