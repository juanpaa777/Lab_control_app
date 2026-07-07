import '../entities/equipment.dart';
import '../entities/equipment_category.dart';

abstract class EquipmentDatasource {
  Future<List<Equipment>> getEquipmentList();
  Future<List<EquipmentCategory>> getCategories();
  Future<Equipment> getEquipmentById(String id);
  Future<void> updateAvailableUnits(String equipmentId, int availableUnits);
}
