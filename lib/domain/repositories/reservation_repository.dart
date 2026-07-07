import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<List<Reservation>> getReservationsByUserId(String userId);
  Future<Reservation> createReservation(Reservation reservation);
  Future<Reservation> cancelReservation(String reservationId);
}
