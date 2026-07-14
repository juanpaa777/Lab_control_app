import 'equipment_model.dart';

class ReservationModel {
  final String id;
  final String userId;
  final EquipmentModel equipment;
  final int quantity;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String status;
  final String qrCode;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.equipment,
    required this.quantity,
    required this.pickupDate,
    required this.returnDate,
    required this.status,
    required this.qrCode,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      equipment: EquipmentModel.fromJson(json['equipment'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      pickupDate: DateTime.parse(json['pickupDate'] as String),
      returnDate: DateTime.parse(json['returnDate'] as String),
      status: json['status'] as String,
      qrCode: json['qrCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'equipment': equipment.toJson(),
      'quantity': quantity,
      'pickupDate': pickupDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'status': status,
      'qrCode': qrCode,
    };
  }
}
