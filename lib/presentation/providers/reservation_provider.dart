import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/domain/datasources/reservation_datasource.dart';
import 'package:lab_control_app/domain/entities/reservation.dart';
import 'package:lab_control_app/domain/repositories/reservation_repository.dart';
import 'package:lab_control_app/infrastructure/datasources/api_reservation_datasource.dart';
// import 'package:lab_control_app/infrastructure/datasources/mock_reservation_datasource.dart'; // Descomentar para usar mocks
import 'package:lab_control_app/infrastructure/repositories/reservation_repository_impl.dart';
import 'auth_provider.dart';
import 'package:lab_control_app/domain/entities/user.dart';
import 'equipment_provider.dart';
import 'dio_provider.dart';

// 1. Proporcionar el Datasource (Conectado a la API mediante Dio)
final reservationDatasourceProvider = Provider<ReservationDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiReservationDatasource(dio);

  // Para volver temporalmente a mocks si el backend no está corriendo, descomenta la siguiente línea y comenta la anterior:
  // return MockReservationDatasource();
});

// 2. Proporcionar el Repositorio
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  final datasource = ref.watch(reservationDatasourceProvider);
  return ReservationRepositoryImpl(datasource);
});

// 3. Notificador de Reservas del usuario autenticado
class ReservationNotifier extends StateNotifier<AsyncValue<List<Reservation>>> {
  final ReservationRepository repository;
  final Ref ref;

  ReservationNotifier(this.repository, this.ref) : super(const AsyncValue.loading()) {
    // Escucha cambios de autenticación para refrescar las reservas del usuario activo
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        loadReservations(next.user!);
      } else {
        state = const AsyncValue.data([]);
      }
    });

    // Carga inicial si el usuario ya está autenticado
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null) {
      loadReservations(currentUser);
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadReservations(User user) async {
    state = const AsyncValue.loading();
    try {
      final List<Reservation> list;
      if (user.role == 'admin') {
        list = await repository.getAllReservations();
      } else {
        list = await repository.getReservationsByUserId(user.id);
      }
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Crear una nueva reserva con validaciones
  Future<Reservation> makeReservation({
    required String equipmentId,
    required int quantity,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      throw Exception('Inicia sesión para realizar una reserva.');
    }

    // Obtener los datos del equipo actual del store local
    final equipmentListAsync = ref.read(equipmentListProvider);
    final equipmentList = equipmentListAsync.value ?? [];
    final eq = equipmentList.firstWhere(
      (e) => e.id == equipmentId,
      orElse: () => throw Exception('Equipo no encontrado.'),
    );

    // Creamos la instancia inicial de la reserva
    final newRes = Reservation(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      equipment: eq,
      quantity: quantity,
      pickupDate: pickupDate,
      returnDate: returnDate,
      status: ReservationStatus.pending,
      qrCode: 'labcontrol-res-${DateTime.now().millisecondsSinceEpoch}-${user.id}-${eq.code}',
    );

    // Enviar a la infraestructura para persistencia y validaciones de negocio en el datasource
    final savedRes = await repository.createReservation(newRes);

    // Actualizamos el stock local de la lista de equipos en la interfaz de manera reactiva
    ref.read(equipmentListProvider.notifier).updateStockLocal(
      eq.id,
      eq.availableUnits - quantity,
    );

    // Agregamos la reserva a la lista de reservas local en memoria
    state.whenData((list) {
      state = AsyncValue.data([savedRes, ...list]);
    });

    return savedRes;
  }

  // Cancelar una reserva activa
  Future<void> cancelReservation(String reservationId) async {
    try {
      // Cancelar en el repositorio (esto actualiza y restaura el stock en el datasource de equipos)
      final updatedRes = await repository.cancelReservation(reservationId);
      
      // Actualizar el stock local del equipo en la interfaz
      ref.read(equipmentListProvider.notifier).updateStockLocal(
        updatedRes.equipment.id,
        updatedRes.equipment.availableUnits,
      );

      // Actualizar el estado de la reserva en la lista localmente
      state.whenData((list) {
        final updatedList = list.map((res) {
          if (res.id == reservationId) {
            return updatedRes;
          }
          return res;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e) {
      throw Exception('No se pudo cancelar la reserva: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Actualizar el estado de una reserva (para administradores)
  Future<void> updateStatus(String reservationId, ReservationStatus newStatus) async {
    try {
      final updatedRes = await repository.updateReservationStatus(reservationId, newStatus.name);

      // Actualizar el estado de la reserva en la lista localmente
      state.whenData((list) {
        final updatedList = list.map((res) {
          if (res.id == reservationId) {
            return updatedRes;
          }
          return res;
        }).toList();
        state = AsyncValue.data(updatedList);
      });

      // Actualizar el stock local del equipo en la interfaz
      ref.read(equipmentListProvider.notifier).updateStockLocal(
        updatedRes.equipment.id,
        updatedRes.equipment.availableUnits,
      );
    } catch (e) {
      throw Exception('No se pudo actualizar el estado de la reserva: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}

// Proveedor global para gestionar las reservas
final reservationProvider = StateNotifierProvider<ReservationNotifier, AsyncValue<List<Reservation>>>((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return ReservationNotifier(repository, ref);
});
