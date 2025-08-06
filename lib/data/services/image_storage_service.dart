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

      // Validar que el archivo existe
      if (!imageFile.existsSync()) {
        developer.log('❌ Error: El archivo de imagen no existe');
        return null;
      }

      // Validar que el serviceId no esté vacío
      if (serviceId.isEmpty) {
        developer.log('❌ Error: serviceId está vacío');
        return null;
      }

      // Validar tamaño del archivo (máximo 10MB como en las reglas)
      final fileSize = imageFile.lengthSync();
      if (fileSize > 10 * 1024 * 1024) {
        developer.log('❌ Error: Imagen demasiado grande (máximo 10MB)');
        return null;
      }

      // Generar nombre único para la imagen
      final String fileName = '${serviceId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Referencia al archivo en Firebase Storage
      final Reference ref = firebaseStorage
          .ref()
          .child(AppConstants.serviceImagesPath)
          .child(fileName);

      // Configurar metadatos para mejor manejo
      final metadata = SettableMetadata(
        contentType: _getContentType(path.extension(imageFile.path)),
        customMetadata: {
          'serviceId': serviceId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Subir archivo directamente sin reintentos complejos
      developer.log('📤 Subiendo imagen de servicio: $fileName');
      
      try {
        final UploadTask uploadTask = ref.putFile(imageFile, metadata);
        
        // Monitorear el progreso (opcional)
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          developer.log('🔄 Progreso de subida: ${progress.toStringAsFixed(1)}%');
        });
        
        // Esperar a que se complete la subida
        final TaskSnapshot snapshot = await uploadTask;
        
        // Verificar que la subida fue exitosa
        if (snapshot.state == TaskState.success) {
          // Obtener URL de descarga
          final String downloadUrl = await snapshot.ref.getDownloadURL();
          developer.log('✅ Imagen de servicio subida exitosamente: $downloadUrl');
          return downloadUrl;
        } else {
          developer.log('❌ Error en el estado de la subida: ${snapshot.state}');
          return null;
        }
        
      } catch (uploadError) {
        developer.log('❌ Error durante la subida: $uploadError');
        
        // Si el error es de sesión terminada, intentar una vez más
        if (uploadError.toString().contains('server has terminated') || 
            uploadError.toString().contains('session')) {
          developer.log('🔄 Reintentando subida por error de sesión...');
          await Future.delayed(const Duration(seconds: 2));
          
          try {
            final retryTask = ref.putFile(imageFile, metadata);
            final retrySnapshot = await retryTask;
            
            if (retrySnapshot.state == TaskState.success) {
              final String downloadUrl = await retrySnapshot.ref.getDownloadURL();
              developer.log('✅ Imagen subida exitosamente en reintento: $downloadUrl');
              return downloadUrl;
            }
          } catch (retryError) {
            developer.log('❌ Error en reintento: $retryError');
          }
        }
        
        return null;
      }
      
    } catch (e) {
      developer.log('❌ Error general al subir imagen de servicio: $e');
      return null;
    }
  }

  /// Determina el content type basado en la extensión del archivo
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Por defecto
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
      
      if (imageFiles.isEmpty) {
        developer.log('⚠️ Lista de imágenes vacía');
        return uploadedUrls;
      }
      
      developer.log('📤 Subiendo ${imageFiles.length} imágenes de servicio...');
      
      // Subir imágenes en paralelo para mejor rendimiento
      final futures = imageFiles.map((imageFile) => uploadServiceImage(serviceId, imageFile));
      final results = await Future.wait(futures);
      
      // Filtrar resultados exitosos
      for (final url in results) {
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
      
      developer.log('✅ ${uploadedUrls.length}/${imageFiles.length} imágenes de servicio subidas exitosamente');
      
      if (uploadedUrls.length < imageFiles.length) {
        final failed = imageFiles.length - uploadedUrls.length;
        developer.log('⚠️ $failed imágenes fallaron al subir');
      }
      
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