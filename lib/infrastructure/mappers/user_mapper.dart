import 'package:lab_control_app/domain/entities/user.dart';
import '../models/user_model.dart';

class UserMapper {
  static User modelToEntity(UserModel model) {
    return User(
      id: model.id,
      name: model.name,
      email: model.email,
      studentId: model.studentId,
      career: model.career,
    );
  }

  static UserModel entityToModel(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      studentId: entity.studentId,
      career: entity.career,
    );
  }
}
