import 'package:dio/dio.dart';
import 'package:lab_control_app/domain/datasources/auth_datasource.dart';
import 'package:lab_control_app/domain/entities/user.dart';
import 'package:lab_control_app/infrastructure/mappers/user_mapper.dart';
import 'package:lab_control_app/infrastructure/models/user_model.dart';

class ApiAuthDatasource implements AuthDatasource {
  final Dio dio;

  ApiAuthDatasource(this.dio);

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final userModel = UserModel.fromJson(response.data as Map<String, dynamic>);
      return UserMapper.modelToEntity(userModel);
    } on DioException catch (e) {
      _handleDioError(e, 'Credenciales incorrectas. Intenta de nuevo.');
    }
    throw Exception('Error inesperado de autenticación.');
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
    String? career,
    required String role,
  }) async {
    try {
      final response = await dio.post('/auth/register', data: {
        'name': name,
        'email': email.trim(),
        'password': password,
        'studentId': studentId,
        'career': career,
        'role': role,
      });
      final userModel = UserModel.fromJson(response.data as Map<String, dynamic>);
      return UserMapper.modelToEntity(userModel);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al registrar al estudiante.');
    }
    throw Exception('Error inesperado en el registro.');
  }

  @override
  Future<User?> getCurrentUser() async {
    // La sesión activa se gestionará en el Riverpod provider a nivel de cliente para esta fase.
    return null;
  }

  @override
  Future<void> logout() async {
    // Limpieza de estados locales en provider.
  }

  void _handleDioError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw Exception('El servidor no está disponible. Comprueba tu conexión con el backend.');
    }
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    }
    throw Exception(defaultMessage);
  }
}
