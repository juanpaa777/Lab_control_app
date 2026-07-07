import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'equipment.dart';

class Reservation {
  final String id;
  final String userId;
  final Equipment equipment;
  final int quantity;
  final DateTime pickupDate;
  final DateTime returnDate;
  final ReservationStatus status;
  final String qrCode;

  const Reservation({
    required this.id,
    required this.userId,
    required this.equipment,
    required this.quantity,
    required this.pickupDate,
    required this.returnDate,
    required this.status,
    required this.qrCode,
  });

  Reservation copyWith({
    String? id,
    String? userId,
    Equipment? equipment,
    int? quantity,
    DateTime? pickupDate,
    DateTime? returnDate,
    ReservationStatus? status,
    String? qrCode,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      equipment: equipment ?? this.equipment,
      quantity: quantity ?? this.quantity,
      pickupDate: pickupDate ?? this.pickupDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
