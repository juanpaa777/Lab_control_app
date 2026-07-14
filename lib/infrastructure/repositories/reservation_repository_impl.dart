import 'package:lab_control_app/domain/datasources/reservation_datasource.dart';
import 'package:lab_control_app/domain/entities/reservation.dart';
import 'package:lab_control_app/domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationDatasource datasource;

  ReservationRepositoryImpl(this.datasource);

  @override
  Future<List<Reservation>> getReservationsByUserId(String userId) {
    return datasource.getReservationsByUserId(userId);
  }

  @override
  Future<Reservation> createReservation(Reservation reservation) {
    return datasource.createReservation(reservation);
  }

  @override
  Future<Reservation> cancelReservation(String reservationId) {
    return datasource.cancelReservation(reservationId);
  }
}
