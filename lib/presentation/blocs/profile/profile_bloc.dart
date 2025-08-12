import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../../../data/services/image_storage_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../auth/auth_state.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ImageStorageService _imageStorageService;
  final FirestoreService _firestoreService;
  final AuthBloc _authBloc;

  ProfileBloc({
    required ImageStorageService imageStorageService,
    required FirestoreService firestoreService,
    required AuthBloc authBloc,
  })  : _imageStorageService = imageStorageService,
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
      
      // Subir nueva imagen a Firebase Storage
      final newPhotoUrl = await _imageStorageService.updateProfileImage(
        currentUser.id,
        event.imageFile,
        currentUser.photoUrl,
      );

      if (newPhotoUrl == null) {
        emit(const ProfileError('Error al subir la imagen a Firebase Storage'));
        return;
      }

      // Actualizar usuario en Firestore con la nueva URL de Firebase Storage
      final updatedUser = UserEntity(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        photoUrl: newPhotoUrl,
        phoneNumber: currentUser.phoneNumber,
        bio: currentUser.bio,
        location: currentUser.location,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createOrUpdateUser(updatedUser);

      // Intentar sincronizar también la foto con FirebaseAuth (para display en otros lugares)
      try {
        final authUser = _authBloc.state is AuthAuthenticated
            ? (_authBloc.state as AuthAuthenticated).user
            : null;
        // Si tenemos un usuario autenticado en FirebaseAuth, actualizar photoURL
        if (authUser != null) {
          await FirebaseAuth.instance.currentUser?.updatePhotoURL(newPhotoUrl);
        }
      } catch (_) {}

      // Actualizar el AuthBloc con el usuario actualizado
      _authBloc.add(AuthUserUpdated(updatedUser));

      emit(ProfilePhotoUpdated(newPhotoUrl));
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

      // Eliminar imagen actual si existe en Firebase Storage
      if (currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty) {
        await _imageStorageService.deleteProfileImage(currentUser.photoUrl!);
      }

      // Actualizar usuario en Firestore (sin foto)
      final updatedUser = UserEntity(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        photoUrl: null,
        phoneNumber: currentUser.phoneNumber,
        bio: currentUser.bio,
        location: currentUser.location,
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