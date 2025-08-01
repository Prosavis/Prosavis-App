import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class LocalImageStorageService {
  static const String _profileImageKey = 'profile_image_path';

  /// Guarda una imagen de perfil localmente y retorna la ruta
  Future<String?> saveProfileImageLocally(String userId, File imageFile) async {
    try {
      // Obtener directorio de documentos de la app
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String profileImagesDir = path.join(appDocDir.path, 'profile_images');
      
      // Crear directorio si no existe
      final Directory profileDir = Directory(profileImagesDir);
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      // Generar nombre único para la imagen
      final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String newPath = path.join(profileImagesDir, fileName);

      // Copiar imagen al directorio de la app
      final File newImage = await imageFile.copy(newPath);
      
      // Guardar ruta en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_profileImageKey}_$userId', newImage.path);
      
      developer.log('✅ Imagen de perfil guardada localmente: ${newImage.path}');
      return newImage.path;
      
    } catch (e) {
      developer.log('❌ Error al guardar imagen localmente: $e');
      return null;
    }
  }

  /// Obtiene la ruta de la imagen de perfil del usuario
  Future<String?> getProfileImagePath(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? imagePath = prefs.getString('${_profileImageKey}_$userId');
      
      // Verificar que el archivo aún existe
      if (imagePath != null) {
        final File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          return imagePath;
        } else {
          // Limpiar referencia si el archivo no existe
          await prefs.remove('${_profileImageKey}_$userId');
        }
      }
      
      return null;
    } catch (e) {
      developer.log('❌ Error al obtener ruta de imagen: $e');
      return null;
    }
  }

  /// Elimina la imagen de perfil local
  Future<bool> deleteProfileImage(String userId, String? imagePath) async {
    try {
      if (imagePath != null) {
        final File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
      
      // Limpiar referencia en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_profileImageKey}_$userId');
      
      developer.log('✅ Imagen de perfil eliminada exitosamente');
      return true;
      
    } catch (e) {
      developer.log('❌ Error al eliminar imagen de perfil: $e');
      return false;
    }
  }

  /// Actualiza la imagen de perfil (elimina la anterior si existe y guarda la nueva)
  Future<String?> updateProfileImage(String userId, File newImageFile, String? currentImagePath) async {
    try {
      // Eliminar imagen anterior si existe
      if (currentImagePath != null) {
        await deleteProfileImage(userId, currentImagePath);
      }
      
      // Guardar nueva imagen
      return await saveProfileImageLocally(userId, newImageFile);
      
    } catch (e) {
      developer.log('❌ Error al actualizar imagen de perfil: $e');
      return null;
    }
  }

  /// Limpia todas las imágenes antiguas (función de mantenimiento)
  Future<void> cleanupOldImages() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String profileImagesDir = path.join(appDocDir.path, 'profile_images');
      final Directory profileDir = Directory(profileImagesDir);
      
      if (await profileDir.exists()) {
        final List<FileSystemEntity> files = profileDir.listSync();
        final DateTime cutoff = DateTime.now().subtract(const Duration(days: 30));
        
        for (final file in files) {
          if (file is File) {
            final FileStat stat = await file.stat();
            if (stat.modified.isBefore(cutoff)) {
              await file.delete();
              developer.log('🧹 Imagen antigua eliminada: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      developer.log('❌ Error en limpieza de imágenes: $e');
    }
  }
}