import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../data/services/local_image_storage_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../auth/auth_state.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final LocalImageStorageService _localImageStorageService;
  final FirestoreService _firestoreService;
  final AuthBloc _authBloc;

  ProfileBloc({
    required LocalImageStorageService localImageStorageService,
    required FirestoreService firestoreService,
    required AuthBloc authBloc,
  })  : _localImageStorageService = localImageStorageService,
        _firestoreService = firestoreService,
        _authBloc = authBloc,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfilePhoto>(_onUpdateProfilePhoto);
    on<RemoveProfilePhoto>(_onRemoveProfilePhoto);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());

    try {
      // Obtener usuario actual del AuthBloc
      final authState = _authBloc.state;
      if (authState is! AuthAuthenticated) {
        emit(const ProfileError('Usuario no autenticado'));
        return;
      }

      final currentUser = authState.user;
      
      // Cargar datos completos del usuario desde Firestore
      final userData = await _firestoreService.getUserById(currentUser.id);
      
      if (userData != null) {
        emit(ProfileLoaded(userData));
        developer.log('✅ Datos del perfil cargados exitosamente');
      } else {
        // Si no hay datos adicionales, usar los del AuthBloc
        emit(ProfileLoaded(currentUser));
        developer.log('📄 Usando datos básicos del usuario autenticado');
      }

    } catch (e) {
      developer.log('❌ Error al cargar datos del perfil: $e');
      emit(ProfileError('Error al cargar datos del perfil: $e'));
    }
  }

  Future<void> _onUpdateProfilePhoto(
    UpdateProfilePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());

    try {
      // Obtener usuario actual del AuthBloc
      final authState = _authBloc.state;
      if (authState is! AuthAuthenticated) {
        emit(const ProfileError('Usuario no autenticado'));
        return;
      }

      final currentUser = authState.user;
      
      // Guardar nueva imagen localmente
      final newPhotoPath = await _localImageStorageService.updateProfileImage(
        currentUser.id,
        event.imageFile,
        currentUser.photoUrl,
      );

      if (newPhotoPath == null) {
        emit(const ProfileError('Error al guardar la imagen'));
        return;
      }

      // Actualizar usuario en Firestore con la nueva ruta local
      final updatedUser = UserEntity(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        photoUrl: newPhotoPath,
        phoneNumber: currentUser.phoneNumber,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createOrUpdateUser(updatedUser);

      // Actualizar el AuthBloc con el usuario actualizado
      _authBloc.add(AuthUserUpdated(updatedUser));

      emit(ProfilePhotoUpdated(newPhotoPath));
      developer.log('✅ Foto de perfil actualizada exitosamente');

    } catch (e) {
      developer.log('❌ Error al actualizar foto de perfil: $e');
      emit(ProfileError('Error al actualizar la foto: $e'));
    }
  }

  Future<void> _onRemoveProfilePhoto(
    RemoveProfilePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());

    try {
      // Obtener usuario actual del AuthBloc
      final authState = _authBloc.state;
      if (authState is! AuthAuthenticated) {
        emit(const ProfileError('Usuario no autenticado'));
        return;
      }

      final currentUser = authState.user;

      // Eliminar imagen actual si existe
      if (currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty) {
        await _localImageStorageService.deleteProfileImage(currentUser.id, currentUser.photoUrl);
      }

      // Actualizar usuario en Firestore (sin foto)
      final updatedUser = UserEntity(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        photoUrl: null,
        phoneNumber: currentUser.phoneNumber,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createOrUpdateUser(updatedUser);

      // Actualizar el AuthBloc con el usuario actualizado
      _authBloc.add(AuthUserUpdated(updatedUser));

      emit(ProfilePhotoRemoved());
      developer.log('✅ Foto de perfil eliminada exitosamente');

    } catch (e) {
      developer.log('❌ Error al eliminar foto de perfil: $e');
      emit(ProfileError('Error al eliminar la foto: $e'));
    }
  }
}