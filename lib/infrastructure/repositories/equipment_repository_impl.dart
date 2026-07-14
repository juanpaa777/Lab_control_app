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
}
