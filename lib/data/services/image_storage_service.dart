import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';
import 'firebase_service.dart';

class ImageStorageService {
  static FirebaseStorage? _storage;
  static bool get isDevelopmentMode => FirebaseService.isDevelopmentMode;

  FirebaseStorage? get storage {
    if (isDevelopmentMode) return null;
    _storage ??= FirebaseStorage.instance;
    return _storage;
  }

  /// Sube una imagen de perfil y retorna la URL de descarga
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      if (isDevelopmentMode) {
        developer.log('🔧 Modo desarrollo: guardando imagen localmente');
        // En modo desarrollo, devolver la ruta local del archivo
        return imageFile.path;
      }

      final firebaseStorage = storage;
      if (firebaseStorage == null) {
        throw Exception('Firebase Storage no está disponible');
      }

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
      if (isDevelopmentMode) {
        developer.log('🔧 Modo desarrollo: imagen eliminada (simulado)');
        // En modo desarrollo, simular eliminación exitosa
        return true;
      }

      final firebaseStorage = storage;
      if (firebaseStorage == null) {
        throw Exception('Firebase Storage no está disponible');
      }

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
      // Si hay una imagen actual y no estamos en modo desarrollo, eliminarla primero
      if (currentImageUrl != null && currentImageUrl.isNotEmpty && !isDevelopmentMode) {
        await deleteProfileImage(currentImageUrl);
      }
      
      // Subir nueva imagen
      return await uploadProfileImage(userId, newImageFile);
      
    } catch (e) {
      developer.log('❌ Error al actualizar imagen de perfil: $e');
      return null;
    }
  }
}