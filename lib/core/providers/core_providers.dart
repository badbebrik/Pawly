import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../../app/router/app_router.dart';
import '../network/api_client.dart';
import '../network/clients/acl_api_client.dart';
import '../network/clients/auth_api_client.dart';
import '../network/clients/catalog_api_client.dart';
import '../network/clients/pets_api_client.dart';
import '../network/clients/profile_api_client.dart';
import '../network/dio_factory.dart';
import '../network/session/auth_session_store.dart';
import '../services/google_sign_in_service.dart';
import '../services/media_picker_service.dart';
import '../storage/secure_storage_service.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(storage);
});

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthSessionStore(secureStorage);
});

final dioBundleProvider = Provider<DioBundle>((ref) {
  final sessionStore = ref.watch(authSessionStoreProvider);
  return DioFactory.create(sessionStore: sessionStore);
});

final dioProvider = Provider<Dio>((ref) {
  final bundle = ref.watch(dioBundleProvider);
  return bundle.dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiClient(apiClient);
});

final profileApiClientProvider = Provider<ProfileApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileApiClient(apiClient);
});

final petsApiClientProvider = Provider<PetsApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PetsApiClient(apiClient);
});

final aclApiClientProvider = Provider<AclApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AclApiClient(apiClient);
});

final catalogApiClientProvider = Provider<CatalogApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CatalogApiClient(apiClient);
});

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  final imagePicker = ref.watch(imagePickerProvider);
  return MediaPickerService(imagePicker);
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return FallbackGoogleSignInService();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
