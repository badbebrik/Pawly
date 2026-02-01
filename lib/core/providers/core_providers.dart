import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../../app/router/app_router.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
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

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthInterceptor(secureStorage);
});

final dioProvider = Provider<Dio>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  return DioClient.create(authInterceptor: authInterceptor);
});

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  final imagePicker = ref.watch(imagePickerProvider);
  return MediaPickerService(imagePicker);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
