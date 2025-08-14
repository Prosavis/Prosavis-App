import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/saved_address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import '../models/saved_address_model.dart';
import '../services/firestore_service.dart';

class AddressRepositoryImpl implements AddressRepository {
  final FirestoreService firestoreService;

  AddressRepositoryImpl(this.firestoreService);

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return FirestoreService.firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');
  }

  @override
  Future<SavedAddressEntity> addAddress(SavedAddressEntity address) async {
    final model = SavedAddressModel.fromEntity(address);
    final ref = _collection(address.userId).doc(address.id);
    await ref.set(model.toJson());

    // Si es default, limpiar otros y marcar este
    if (address.isDefault) {
      await setDefaultAddress(address.userId, address.id);
    }

    return address;
  }

  @override
  Future<void> updateAddress(SavedAddressEntity address) async {
    await _collection(address.userId)
        .doc(address.id)
        .set(SavedAddressModel.fromEntity(address).toJson(), SetOptions(merge: true));

    if (address.isDefault) {
      await setDefaultAddress(address.userId, address.id);
    }
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    await _collection(userId).doc(addressId).delete();
  }

  @override
  Future<List<SavedAddressEntity>> getUserAddresses(String userId) async {
    final snapshot = await _collection(userId)
        .orderBy('isDefault', descending: true)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((d) => SavedAddressModel.fromJson(d.data()))
        .toList();
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    final batch = FirestoreService.firestore.batch();
    final col = _collection(userId);

    final existing = await col.get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }
}


