import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lab_control_app/domain/datasources/equipment_datasource.dart';
import 'package:lab_control_app/domain/entities/equipment.dart';
import 'package:lab_control_app/domain/entities/equipment_category.dart';
import 'package:lab_control_app/domain/repositories/equipment_repository.dart';
import 'package:lab_control_app/infrastructure/datasources/api_equipment_datasource.dart';
// import 'package:lab_control_app/infrastructure/datasources/mock_equipment_datasource.dart'; // Descomentar para usar mocks
import 'package:lab_control_app/infrastructure/repositories/equipment_repository_impl.dart';
import 'dio_provider.dart';

// 1. Proporcionar el Datasource (Conectado a la API mediante Dio)
final equipmentDatasourceProvider = Provider<EquipmentDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiEquipmentDatasource(dio);

  // Para volver temporalmente a mocks si el backend no está corriendo, descomenta la siguiente línea y comenta la anterior:
  // return MockEquipmentDatasource();
});

// 2. Proporcionar el Repositorio
final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  final datasource = ref.watch(equipmentDatasourceProvider);
  return EquipmentRepositoryImpl(datasource);
});

// 3. Notificador para la lista de equipos en tiempo real (estado local)
class EquipmentListNotifier extends StateNotifier<AsyncValue<List<Equipment>>> {
  final EquipmentRepository repository;

  EquipmentListNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadEquipment();
  }

  Future<void> loadEquipment() async {
    state = const AsyncValue.loading();
    try {
      final list = await repository.getEquipmentList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Permite actualizar la disponibilidad del equipo localmente cuando se crea/cancela una reserva
  void updateStockLocal(String id, int newStock) {
    state.whenData((list) {
      final updatedList = list.map((eq) {
        if (eq.id == id) {
          return eq.copyWith(availableUnits: newStock);
        }
        return eq;
      }).toList();
      state = AsyncValue.data(updatedList);
    });
  }

  Future<void> createEquipment({
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  }) async {
    final newEq = await repository.createEquipment(
      name: name,
      categoryId: categoryId,
      code: code,
      location: location,
      totalUnits: totalUnits,
      imageUrl: imageUrl,
    );
    state.whenData((list) {
      state = AsyncValue.data([...list, newEq]);
    });
  }

  Future<void> updateEquipment({
    required String id,
    required String name,
    required String categoryId,
    required String code,
    required String location,
    required int totalUnits,
    required String imageUrl,
  }) async {
    final updatedEq = await repository.updateEquipment(
      id: id,
      name: name,
      categoryId: categoryId,
      code: code,
      location: location,
      totalUnits: totalUnits,
      imageUrl: imageUrl,
    );
    state.whenData((list) {
      final updatedList = list.map((eq) => eq.id == id ? updatedEq : eq).toList();
      state = AsyncValue.data(updatedList);
    });
  }

  Future<void> deleteEquipment(String id) async {
    await repository.deleteEquipment(id);
    state.whenData((list) {
      final updatedList = list.where((eq) => eq.id != id).toList();
      state = AsyncValue.data(updatedList);
    });
  }
}

// Proveedor global para la lista total de equipos
final equipmentListProvider = StateNotifierProvider<EquipmentListNotifier, AsyncValue<List<Equipment>>>((ref) {
  final repository = ref.watch(equipmentRepositoryProvider);
  return EquipmentListNotifier(repository);
});

// 4. Proveedor para la lista de categorías
final categoriesProvider = FutureProvider<List<EquipmentCategory>>((ref) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.getCategories();
});

// 5. Estado de la categoría seleccionada (null significa "Todos")
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

// 6. Estado del texto de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// 7. Proveedor combinado para la lista filtrada de equipos (Búsqueda local + Filtro por categoría)
final filteredEquipmentProvider = Provider<List<Equipment>>((ref) {
  final equipmentAsync = ref.watch(equipmentListProvider);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  return equipmentAsync.when(
    data: (list) {
      return list.where((eq) {
        final matchesCategory = selectedCategoryId == null || eq.category.id == selectedCategoryId;
        final matchesSearch = eq.name.toLowerCase().contains(searchQuery) ||
                              eq.code.toLowerCase().contains(searchQuery) ||
                              eq.location.toLowerCase().contains(searchQuery);
        return matchesCategory && matchesSearch;
      }).toList();
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
