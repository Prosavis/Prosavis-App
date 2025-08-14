import '../entities/saved_address_entity.dart';

abstract class AddressRepository {
  Future<SavedAddressEntity> addAddress(SavedAddressEntity address);
  Future<void> updateAddress(SavedAddressEntity address);
  Future<void> deleteAddress(String userId, String addressId);
  Future<List<SavedAddressEntity>> getUserAddresses(String userId);
  Future<void> setDefaultAddress(String userId, String addressId);
}


