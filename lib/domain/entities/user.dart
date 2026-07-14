class User {
  final String id;
  final String name;
  final String email;
  final String? studentId; // Matrícula / Registro de estudiante (opcional para admins/docentes)
  final String? career;    // Carrera universitaria (opcional para admins/docentes)
  final String role;       // 'student', 'teacher', 'admin'

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.studentId,
    this.career,
    required this.role,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? career,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      career: career ?? this.career,
      role: role ?? this.role,
    );
  }
}
