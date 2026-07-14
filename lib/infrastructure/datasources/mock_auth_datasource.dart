import 'package:lab_control_app/domain/datasources/auth_datasource.dart';
import 'package:lab_control_app/domain/entities/user.dart';

class MockAuthDatasource implements AuthDatasource {
  User? _currentUser;

  // Datos simulados iniciales
  final List<User> _mockUsers = [
    const User(
      id: 'usr-001',
      name: 'Diego Pardo',
      email: 'diego.pardo@universidad.edu',
      studentId: '202300123',
      career: 'Ingeniería en Sistemas',
    ),
  ];

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Búsqueda simple por correo
    final userIndex = _mockUsers.indexWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase()
    );

    if (userIndex != -1) {
      _currentUser = _mockUsers[userIndex];
      return _currentUser!;
    } else {
      // Registrar un usuario al vuelo con contraseña para simular
      // o lanzar error si no existe
      if (email.contains('@')) {
        final name = email.split('@')[0];
        final newUser = User(
          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
          name: name[0].toUpperCase() + name.substring(1),
          email: email,
          studentId: '2023${DateTime.now().millisecond}',
          career: 'Ingeniería en Computación',
        );
        _mockUsers.add(newUser);
        _currentUser = newUser;
        return newUser;
      }
      throw Exception('Credenciales incorrectas');
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String career,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final exists = _mockUsers.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());
    if (exists) {
      throw Exception('El correo ya está registrado');
    }

    final newUser = User(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      studentId: studentId,
      career: career,
    );

    _mockUsers.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
