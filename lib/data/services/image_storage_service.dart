import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';

class ImageStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen de perfil y retorna la URL de descarga
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Generar nombre único para la imagen
      final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Referencia al archivo en Firebase Storage
      final Reference ref = _storage
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
      // Obtener referencia desde la URL
      final Reference ref = _storage.refFromURL(imageUrl);
      
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
}