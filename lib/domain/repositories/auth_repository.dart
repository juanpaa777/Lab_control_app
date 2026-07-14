import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
    String? career,
    required String role,
  });
  Future<User?> getCurrentUser();
  Future<void> logout();
}
