import 'package:lab_control_app/domain/datasources/equipment_datasource.dart';
import 'package:lab_control_app/domain/entities/equipment.dart';
import 'package:lab_control_app/domain/entities/equipment_category.dart';

class MockEquipmentDatasource implements EquipmentDatasource {
  static final List<EquipmentCategory> _categories = [
    const EquipmentCategory(id: 'cat-1', name: 'Electrónica'),
    const EquipmentCategory(id: 'cat-2', name: 'Cómputo'),
    const EquipmentCategory(id: 'cat-3', name: 'Redes'),
  ];

  static final List<Equipment> _equipmentList = [
    Equipment(
      id: 'eq-001',
      name: 'Kit Arduino Uno R3',
      category: _categories[0],
      code: 'EQ-001',
      location: 'Laboratorio 3 - Planta Baja',
      totalUnits: 8,
      availableUnits: 3,
    ),
    Equipment(
      id: 'eq-002',
      name: 'Laptop HP',
      category: _categories[1],
      code: 'EQ-002',
      location: 'Laboratorio 2',
      totalUnits: 5,
      availableUnits: 2,
    ),
    Equipment(
      id: 'eq-003',
      name: 'Cable USB-C',
      category: _categories[0],
      code: 'EQ-003',
      location: 'Almacén de laboratorio',
      totalUnits: 15,
      availableUnits: 10,
    ),
    Equipment(
      id: 'eq-004',
      name: 'Router Cisco',
      category: _categories[2],
      code: 'EQ-004',
      location: 'Laboratorio de Redes',
      totalUnits: 4,
      availableUnits: 1,
    ),
  ];

  @override
  Future<List<Equipment>> getEquipmentList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_equipmentList);
  }

  @override
  Future<List<EquipmentCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_categories);
  }

  @override
  Future<Equipment> getEquipmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final equipment = _equipmentList.firstWhere(
      (eq) => eq.id == id,
      orElse: () => throw Exception('Equipo no encontrado'),
    );
    return equipment;
  }

  @override
  Future<void> updateAvailableUnits(String equipmentId, int availableUnits) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _equipmentList.indexWhere((eq) => eq.id == equipmentId);
    if (index != -1) {
      final eq = _equipmentList[index];
      if (availableUnits < 0 || availableUnits > eq.totalUnits) {
        throw Exception('Unidades disponibles inválidas');
      }
      _equipmentList[index] = eq.copyWith(availableUnits: availableUnits);
    } else {
      throw Exception('Equipo no encontrado');
    }
  }

  @override
  Future<Equipment> createEquipment({
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final category = _categories.firstWhere((c) => c.id == categoryId,
        orElse: () => _categories[0]);
    
    final newEq = Equipment(
      id: 'eq-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      code: code,
      location: location,
      totalUnits: totalUnits,
      availableUnits: totalUnits,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
    _equipmentList.add(newEq);
    return newEq;
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _equipmentList.indexWhere((eq) => eq.id == id);
    if (index == -1) throw Exception('Equipo no encontrado');

    final existingEq = _equipmentList[index];
    final currentlyLent = existingEq.totalUnits - existingEq.availableUnits;
    if (totalUnits < currentlyLent) {
      throw Exception('No puedes reducir el stock por debajo de lo prestado ($currentlyLent)');
    }

    final category = _categories.firstWhere((c) => c.id == categoryId,
        orElse: () => _categories[0]);

    final updatedEq = Equipment(
      id: id,
      name: name,
      category: category,
      code: code,
      location: location,
      totalUnits: totalUnits,
      availableUnits: totalUnits - currentlyLent,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
    _equipmentList[index] = updatedEq;
    return updatedEq;
  }

  @override
  Future<void> deleteEquipment(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _equipmentList.removeWhere((eq) => eq.id == id);
  }
}
