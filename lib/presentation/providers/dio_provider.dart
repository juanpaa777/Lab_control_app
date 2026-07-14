import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lab_control_app/config/constants/environment.dart';

// Proveedor global para el cliente Dio centralizado
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 6), // 6 segundos de tiempo de conexión
      receiveTimeout: const Duration(seconds: 6), // 6 segundos de espera de datos
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
});
