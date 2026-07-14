class UserModel {
  final String id;
  final String name;
  final String email;
  final String? studentId;
  final String? career;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.studentId,
    this.career,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      studentId: json['studentId'] as String?,
      career: json['career'] as String?,
      role: json['role'] as String? ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'career': career,
      'role': role,
    };
  }
}
