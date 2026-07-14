import 'package:lab_control_app/domain/datasources/equipment_datasource.dart';
import 'package:lab_control_app/domain/entities/equipment.dart';
import 'package:lab_control_app/domain/entities/equipment_category.dart';
import 'package:lab_control_app/domain/repositories/equipment_repository.dart';

class EquipmentRepositoryImpl implements EquipmentRepository {
  final EquipmentDatasource datasource;

  EquipmentRepositoryImpl(this.datasource);

  @override
  Future<List<Equipment>> getEquipmentList() {
    return datasource.getEquipmentList();
  }

  @override
  Future<List<EquipmentCategory>> getCategories() {
    return datasource.getCategories();
  }

  @override
  Future<Equipment> getEquipmentById(String id) {
    return datasource.getEquipmentById(id);
  }

  @override
  Future<void> updateAvailableUnits(String equipmentId, int availableUnits) {
    return datasource.updateAvailableUnits(equipmentId, availableUnits);
  }

  @override
  Future<Equipment> createEquipment({
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  }) {
    return datasource.createEquipment(
      name: name,
      categoryId: categoryId,
      code: code,
      location: location,
      totalUnits: totalUnits,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<Equipment> updateEquipment({
    required String id,
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  }) {
    return datasource.updateEquipment(
      id: id,
      name: name,
      categoryId: categoryId,
      code: code,
      location: location,
      totalUnits: totalUnits,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> deleteEquipment(String id) {
    return datasource.deleteEquipment(id);
  }
}
