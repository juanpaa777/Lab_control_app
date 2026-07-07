import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String career,
  });
  Future<User?> getCurrentUser();
  Future<void> logout();
}
