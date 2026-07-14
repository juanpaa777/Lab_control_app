import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<List<Reservation>> getReservationsByUserId(String userId);
  Future<Reservation> createReservation(Reservation reservation);
  Future<Reservation> cancelReservation(String reservationId);
  Future<List<Reservation>> getAllReservations();
  Future<Reservation> updateReservationStatus(String reservationId, String status);
}
