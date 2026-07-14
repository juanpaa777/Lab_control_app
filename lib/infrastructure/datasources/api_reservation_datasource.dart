import 'package:dio/dio.dart';
import 'package:lab_control_app/domain/datasources/reservation_datasource.dart';
import 'package:lab_control_app/domain/entities/reservation.dart';
import 'package:lab_control_app/infrastructure/mappers/reservation_mapper.dart';
import 'package:lab_control_app/infrastructure/models/reservation_model.dart';

class ApiReservationDatasource implements ReservationDatasource {
  final Dio dio;

  ApiReservationDatasource(this.dio);

  @override
  Future<List<Reservation>> getReservationsByUserId(String userId) async {
    try {
      final response = await dio.get('/reservations/user/$userId');
      final list = (response.data as List)
          .map((item) => ReservationModel.fromJson(item as Map<String, dynamic>))
          .map((model) => ReservationMapper.modelToEntity(model))
          .toList();
      return list;
    } on DioException catch (e) {
      _handleDioError(e, 'Error al obtener tus reservas.');
    }
    throw Exception('Error inesperado al cargar reservas.');
  }

  @override
  Future<Reservation> createReservation(Reservation reservation) async {
    try {
      final response = await dio.post('/reservations', data: {
        'userId': reservation.userId,
        'equipmentId': reservation.equipment.id,
        'quantity': reservation.quantity,
        'pickupDate': reservation.pickupDate.toIso8601String(),
        'returnDate': reservation.returnDate.toIso8601String(),
      });
      final model = ReservationModel.fromJson(response.data as Map<String, dynamic>);
      return ReservationMapper.modelToEntity(model);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al crear la reserva.');
    }
    throw Exception('Error inesperado al crear reserva.');
  }

  @override
  Future<Reservation> cancelReservation(String reservationId) async {
    try {
      final response = await dio.patch('/reservations/$reservationId/cancel');
      final model = ReservationModel.fromJson(response.data as Map<String, dynamic>);
      return ReservationMapper.modelToEntity(model);
    } on DioException catch (e) {
      _handleDioError(e, 'Error al cancelar la reserva.');
    }
    throw Exception('Error inesperado al cancelar reserva.');
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
