class User {
  final String id;
  final String name;
  final String email;
  final String studentId; // Matrícula / Registro de estudiante
  final String career;    // Carrera universitaria

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.career,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? career,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      career: career ?? this.career,
    );
  }
}
