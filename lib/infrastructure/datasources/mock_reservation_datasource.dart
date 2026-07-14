import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/domain/datasources/reservation_datasource.dart';
import 'package:lab_control_app/domain/entities/reservation.dart';
import 'package:lab_control_app/infrastructure/datasources/mock_equipment_datasource.dart';

class MockReservationDatasource implements ReservationDatasource {
  static final List<Reservation> _reservations = [];
  final MockEquipmentDatasource _equipmentDatasource = MockEquipmentDatasource();

  @override
  Future<List<Reservation>> getReservationsByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _reservations.where((res) => res.userId == userId).toList();
  }

  @override
  Future<Reservation> createReservation(Reservation reservation) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 1. Validar que el equipo exista y consultar su disponibilidad actual
    final equipment = await _equipmentDatasource.getEquipmentById(reservation.equipment.id);
    
    // 2. Validar stock
    if (equipment.availableUnits <= 0) {
      throw Exception('El equipo no está disponible para préstamo en este momento.');
    }

    if (reservation.quantity > equipment.availableUnits) {
      throw Exception(
        'La cantidad solicitada (${reservation.quantity}) supera las unidades disponibles (${equipment.availableUnits}).'
      );
    }

    // 3. Validar fechas (no anteriores a la fecha y hora actual)
    final now = DateTime.now();
    // Permitir un margen de 5 minutos por retrasos del sistema al rellenar el formulario
    final marginNow = now.subtract(const Duration(minutes: 5));
    if (reservation.pickupDate.isBefore(marginNow)) {
      throw Exception('La fecha de recogida no puede ser en el pasado.');
    }

    // 4. Validar fecha de devolución posterior a la de recogida
    if (!reservation.returnDate.isAfter(reservation.pickupDate)) {
      throw Exception('La fecha de devolución debe ser posterior a la fecha de recogida.');
    }

    // 5. Restar stock del equipo en el catálogo
    final newAvailableUnits = equipment.availableUnits - reservation.quantity;
    await _equipmentDatasource.updateAvailableUnits(equipment.id, newAvailableUnits);

    // 6. Registrar la reserva con el equipo actualizado en stock
    final savedReservation = reservation.copyWith(
      equipment: equipment.copyWith(availableUnits: newAvailableUnits),
    );

    _reservations.add(savedReservation);
    return savedReservation;
  }

  @override
  Future<Reservation> cancelReservation(String reservationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _reservations.indexWhere((res) => res.id == reservationId);
    if (index == -1) {
      throw Exception('Reserva no encontrada');
    }

    final res = _reservations[index];
    if (res.status == ReservationStatus.cancelled) {
      return res;
    }

    // Si se cancela, devolvemos el stock al equipo si estaba pendiente o activa
    if (res.status == ReservationStatus.pending || res.status == ReservationStatus.active) {
      try {
        final equipment = await _equipmentDatasource.getEquipmentById(res.equipment.id);
        final restoredUnits = equipment.availableUnits + res.quantity;
        await _equipmentDatasource.updateAvailableUnits(res.equipment.id, restoredUnits);
      } catch (_) {
        // Ignorar si el equipo ya no existe
      }
    }

    final updatedReservation = res.copyWith(status: ReservationStatus.cancelled);
    _reservations[index] = updatedReservation;
    return updatedReservation;
  }

  @override
  Future<List<Reservation>> getAllReservations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_reservations);
  }

  @override
  Future<Reservation> updateReservationStatus(String reservationId, String status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _reservations.indexWhere((res) => res.id == reservationId);
    if (index == -1) throw Exception('Reserva no encontrada');

    final res = _reservations[index];
    final targetStatus = ReservationStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ReservationStatus.pending
    );

    final wasRestoring = res.status == ReservationStatus.completed || res.status == ReservationStatus.cancelled;
    final isRestoring = targetStatus == ReservationStatus.completed || targetStatus == ReservationStatus.cancelled;

    if (!wasRestoring && isRestoring) {
      try {
        final equipment = await _equipmentDatasource.getEquipmentById(res.equipment.id);
        final restoredUnits = equipment.availableUnits + res.quantity;
        await _equipmentDatasource.updateAvailableUnits(res.equipment.id, restoredUnits);
      } catch (_) {}
    } else if (wasRestoring && !isRestoring) {
      try {
        final equipment = await _equipmentDatasource.getEquipmentById(res.equipment.id);
        final reducedUnits = equipment.availableUnits - res.quantity;
        await _equipmentDatasource.updateAvailableUnits(res.equipment.id, reducedUnits);
      } catch (_) {}
    }

    final updatedRes = res.copyWith(status: targetStatus);
    _reservations[index] = updatedRes;
    return updatedRes;
  }
}
