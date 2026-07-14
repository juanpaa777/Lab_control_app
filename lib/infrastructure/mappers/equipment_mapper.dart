import 'package:lab_control_app/domain/entities/equipment.dart';
import 'package:lab_control_app/domain/entities/equipment_category.dart';
import '../models/equipment_model.dart';
import '../models/equipment_category_model.dart';

class EquipmentMapper {
  static EquipmentCategory categoryModelToEntity(EquipmentCategoryModel model) {
    return EquipmentCategory(
      id: model.id,
      name: model.name,
    );
  }

  static EquipmentCategoryModel categoryEntityToModel(EquipmentCategory entity) {
    return EquipmentCategoryModel(
      id: entity.id,
      name: entity.name,
    );
  }

  static Equipment modelToEntity(EquipmentModel model) {
    return Equipment(
      id: model.id,
      name: model.name,
      category: categoryModelToEntity(model.category),
      code: model.code,
      location: model.location,
      totalUnits: model.totalUnits,
      availableUnits: model.availableUnits,
      imageUrl: model.imageUrl,
    );
  }

  static EquipmentModel entityToModel(Equipment entity) {
    return EquipmentModel(
      id: entity.id,
      name: entity.name,
      category: categoryEntityToModel(entity.category),
      code: entity.code,
      location: entity.location,
      totalUnits: entity.totalUnits,
      availableUnits: entity.availableUnits,
      imageUrl: entity.imageUrl,
    );
  }
}
