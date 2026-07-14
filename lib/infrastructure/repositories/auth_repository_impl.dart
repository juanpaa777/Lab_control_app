import 'package:lab_control_app/domain/datasources/auth_datasource.dart';
import 'package:lab_control_app/domain/entities/user.dart';
import 'package:lab_control_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Future<User> login(String email, String password) {
    return datasource.login(email, password);
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String career,
  }) {
    return datasource.register(
      name: name,
      email: email,
      password: password,
      studentId: studentId,
      career: career,
    );
  }

  @override
  Future<User?> getCurrentUser() {
    return datasource.getCurrentUser();
  }

  @override
  Future<void> logout() {
    return datasource.logout();
  }
}
