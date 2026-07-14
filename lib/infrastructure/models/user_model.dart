class UserModel {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String career;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.career,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      studentId: json['studentId'] as String,
      career: json['career'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'career': career,
    };
  }
}
