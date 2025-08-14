import 'package:equatable/equatable.dart';
import '../../../domain/entities/saved_address_entity.dart';

abstract class AddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<SavedAddressEntity> addresses;
  final SavedAddressEntity? active;
  AddressLoaded({required this.addresses, this.active});

  AddressLoaded copyWith({
    List<SavedAddressEntity>? addresses,
    SavedAddressEntity? active,
  }) {
    return AddressLoaded(
      addresses: addresses ?? this.addresses,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [addresses, active];
}

class AddressError extends AddressState {
  final String message;
  AddressError(this.message);
  @override
  List<Object?> get props => [message];
}


