import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';

class ImageStorageService {
  static FirebaseStorage? _storage;

  FirebaseStorage get storage {
    _storage ??= FirebaseStorage.instance;
    return _storage!;
  }

  /// Sube una imagen de perfil y retorna la URL de descarga
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final firebaseStorage = storage;

      // Generar nombre único para la imagen
      final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Referencia al archivo en Firebase Storage
      final Reference ref = firebaseStorage
          .ref()
          .child(AppConstants.profileImagesPath)
          .child(fileName);

      // Subir archivo
      developer.log('📤 Subiendo imagen de perfil...');
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      // Esperar a que se complete la subida
      final TaskSnapshot snapshot = await uploadTask;
      
      // Obtener URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      developer.log('✅ Imagen de perfil subida exitosamente: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      developer.log('❌ Error al subir imagen de perfil: $e');
      return null;
    }
  }

  /// Elimina una imagen de perfil usando su URL
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final firebaseStorage = storage;

      // Obtener referencia desde la URL
      final Reference ref = firebaseStorage.refFromURL(imageUrl);
      
      // Eliminar imagen
      await ref.delete();
      
      developer.log('✅ Imagen de perfil eliminada exitosamente');
      return true;
      
    } catch (e) {
      developer.log('❌ Error al eliminar imagen de perfil: $e');
      return false;
    }
  }

  /// Actualiza la imagen de perfil (elimina la anterior si existe y sube la nueva)
  Future<String?> updateProfileImage(String userId, File newImageFile, String? currentImageUrl) async {
    try {
      // Si hay una imagen actual, eliminarla primero
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await deleteProfileImage(currentImageUrl);
      }
      
      // Subir nueva imagen
      return await uploadProfileImage(userId, newImageFile);
      
    } catch (e) {
      developer.log('❌ Error al actualizar imagen de perfil: $e');
      return null;
    }
  }

  /// Sube una imagen de servicio y retorna la URL de descarga
  Future<String?> uploadServiceImage(String serviceId, File imageFile) async {
    try {
      final firebaseStorage = storage;

      // Generar nombre único para la imagen
      final String fileName = '${serviceId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Referencia al archivo en Firebase Storage
      final Reference ref = firebaseStorage
          .ref()
          .child(AppConstants.serviceImagesPath)
          .child(fileName);

      // Subir archivo
      developer.log('📤 Subiendo imagen de servicio...');
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      // Esperar a que se complete la subida
      final TaskSnapshot snapshot = await uploadTask;
      
      // Obtener URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      developer.log('✅ Imagen de servicio subida exitosamente: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      developer.log('❌ Error al subir imagen de servicio: $e');
      return null;
    }
  }

  /// Elimina una imagen de servicio usando su URL
  Future<bool> deleteServiceImage(String imageUrl) async {
    try {
      final firebaseStorage = storage;

      // Obtener referencia desde la URL
      final Reference ref = firebaseStorage.refFromURL(imageUrl);
      
      // Eliminar imagen
      await ref.delete();
      
      developer.log('✅ Imagen de servicio eliminada exitosamente');
      return true;
      
    } catch (e) {
      developer.log('❌ Error al eliminar imagen de servicio: $e');
      return false;
    }
  }

  /// Sube múltiples imágenes de servicio y retorna las URLs
  Future<List<String>> uploadMultipleServiceImages(String serviceId, List<File> imageFiles) async {
    try {
      final List<String> uploadedUrls = [];
      
      for (final imageFile in imageFiles) {
        final url = await uploadServiceImage(serviceId, imageFile);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
      
      developer.log('✅ ${uploadedUrls.length}/${imageFiles.length} imágenes de servicio subidas');
      return uploadedUrls;
      
    } catch (e) {
      developer.log('❌ Error al subir múltiples imágenes de servicio: $e');
      return [];
    }
  }

  /// Elimina múltiples imágenes de servicio
  Future<bool> deleteMultipleServiceImages(List<String> imageUrls) async {
    try {
      int deletedCount = 0;
      
      for (final imageUrl in imageUrls) {
        final success = await deleteServiceImage(imageUrl);
        if (success) deletedCount++;
      }
      
      developer.log('✅ $deletedCount/${imageUrls.length} imágenes de servicio eliminadas');
      return deletedCount == imageUrls.length;
      
    } catch (e) {
      developer.log('❌ Error al eliminar múltiples imágenes de servicio: $e');
      return false;
    }
  }
}