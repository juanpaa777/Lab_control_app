import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/domain/entities/reservation.dart';
import '../models/reservation_model.dart';
import 'equipment_mapper.dart';

class ReservationMapper {
  static Reservation modelToEntity(ReservationModel model) {
    return Reservation(
      id: model.id,
      userId: model.userId,
      equipment: EquipmentMapper.modelToEntity(model.equipment),
      quantity: model.quantity,
      pickupDate: model.pickupDate,
      returnDate: model.returnDate,
      status: ReservationStatus.values.byName(model.status),
      qrCode: model.qrCode,
      userName: model.userName,
      userEmail: model.userEmail,
      studentId: model.studentId,
    );
  }

  static ReservationModel entityToModel(Reservation entity) {
    return ReservationModel(
      id: entity.id,
      userId: entity.userId,
      equipment: EquipmentMapper.entityToModel(entity.equipment),
      quantity: entity.quantity,
      pickupDate: entity.pickupDate,
      returnDate: entity.returnDate,
      status: entity.status.name,
      qrCode: entity.qrCode,
      userName: entity.userName,
      userEmail: entity.userEmail,
      studentId: entity.studentId,
    );
  }
}
