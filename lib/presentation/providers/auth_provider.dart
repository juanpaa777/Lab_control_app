import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lab_control_app/domain/datasources/auth_datasource.dart';
import 'package:lab_control_app/domain/entities/user.dart';
import 'package:lab_control_app/domain/repositories/auth_repository.dart';
import 'package:lab_control_app/infrastructure/datasources/api_auth_datasource.dart';
// import 'package:lab_control_app/infrastructure/datasources/mock_auth_datasource.dart'; // Descomentar para usar mocks
import 'package:lab_control_app/infrastructure/repositories/auth_repository_impl.dart';
import 'dio_provider.dart';

// 1. Proporcionar el Datasource (Conectado a la API mediante Dio)
final authDatasourceProvider = Provider<AuthDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiAuthDatasource(dio);

  // Para volver temporalmente a mocks si el backend no está corriendo, descomenta la siguiente línea y comenta la anterior:
  // return MockAuthDatasource();
});

// 2. Proporcionar el Repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authDatasourceProvider);
  return AuthRepositoryImpl(datasource);
});

// 3. Definir el estado de la autenticación
class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthed;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthed = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthed,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Permitir resetear a null si no se pasa
      isAuthed: isAuthed ?? this.isAuthed,
    );
  }
}

// 4. Notificador de Autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;

  AuthNotifier({required this.repository}) : super(AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await repository.getCurrentUser();
      if (user != null) {
        state = state.copyWith(user: user, isAuthed: true, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await repository.login(email, password);
      state = state.copyWith(user: user, isAuthed: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthed: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
    String? career,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await repository.register(
        name: name,
        email: email,
        password: password,
        studentId: studentId,
        career: career,
        role: role,
      );
      state = state.copyWith(user: user, isAuthed: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthed: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await repository.logout();
    state = AuthState(); // Reset a estado inicial vacío
  }
}

// 5. Exponer el proveedor global
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository: repository);
});
