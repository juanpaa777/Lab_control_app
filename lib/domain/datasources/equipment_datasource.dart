import '../entities/equipment.dart';
import '../entities/equipment_category.dart';

abstract class EquipmentDatasource {
  Future<List<Equipment>> getEquipmentList();
  Future<List<EquipmentCategory>> getCategories();
  Future<Equipment> getEquipmentById(String id);
  Future<void> updateAvailableUnits(String equipmentId, int availableUnits);
  Future<Equipment> createEquipment({
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  });
  Future<Equipment> updateEquipment({
    required String id,
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  });
  Future<void> deleteEquipment(String id);
}
