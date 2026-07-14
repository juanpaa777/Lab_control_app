import 'package:dio/dio.dart';
import 'package:lab_control_app/domain/datasources/equipment_datasource.dart';
import 'package:lab_control_app/domain/entities/equipment.dart';
import 'package:lab_control_app/domain/entities/equipment_category.dart';
import 'package:lab_control_app/infrastructure/mappers/equipment_mapper.dart';
import 'package:lab_control_app/infrastructure/models/equipment_model.dart';
import 'package:lab_control_app/infrastructure/models/equipment_category_model.dart';

class ApiEquipmentDatasource implements EquipmentDatasource {
  final Dio dio;

  ApiEquipmentDatasource(this.dio);

  @override
  Future<List<Equipment>> getEquipmentList() async {
    try {
      final response = await dio.get('/equipment');
      final list = (response.data as List)
          .map((item) => EquipmentModel.fromJson(item as Map<String, dynamic>))
          .map((model) => EquipmentMapper.modelToEntity(model))
          .toList();
      return list;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar el inventario de equipos.');
    }
    throw Exception('Error inesperado al cargar inventario.');
  }

  @override
  Future<List<EquipmentCategory>> getCategories() async {
    try {
      final response = await dio.get('/equipment/categories');
      final list = (response.data as List)
          .map((item) => EquipmentCategoryModel.fromJson(item as Map<String, dynamic>))
          .map((model) => EquipmentMapper.categoryModelToEntity(model))
          .toList();
      return list;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar las categorías de equipos.');
    }
    throw Exception('Error inesperado al cargar categorías.');
  }

  @override
  Future<Equipment> getEquipmentById(String id) async {
    try {
      final response = await dio.get('/equipment/$id');
      final model = EquipmentModel.fromJson(response.data as Map<String, dynamic>);
      return EquipmentMapper.modelToEntity(model);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cargar el detalle del equipo.');
    }
    throw Exception('Error inesperado al cargar el equipo.');
  }

  @override
  Future<void> updateAvailableUnits(String equipmentId, int availableUnits) async {
    // Nota: El backend de PostgreSQL gestiona la disponibilidad transaccional de forma automática.
    // Esta función del contrato se mantiene como una operación local exitosa para preservar la interfaz.
    return;
  }

  void _handleDioError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw Exception('El servidor no está disponible. Comprueba tu conexión con el backend.');
    }
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        throw Exception(data['error']);
      }
    }
    throw Exception(defaultMessage);
  }
}
