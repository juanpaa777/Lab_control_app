import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/providers/auth_provider.dart';
import 'package:lab_control_app/presentation/providers/reservation_provider.dart';
import 'package:lab_control_app/presentation/widgets/reservations/reservation_card.dart';

class ReservationsView extends ConsumerWidget {
  const ReservationsView({super.key});

  void _confirmCancel(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: Text('¿Estás seguro de cancelar tu reserva del equipo "$name"? El stock se liberará de inmediato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(reservationProvider.notifier).cancelReservation(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva cancelada exitosamente'),
                      backgroundColor: AppTheme.available,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.unavailable,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.unavailable,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String id, ReservationStatus newStatus, String actionLabel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Marcar como $actionLabel?'),
        content: Text('¿Estás seguro de que deseas marcar este equipo como $actionLabel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(reservationProvider.notifier).updateStatus(id, newStatus);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estado de la reserva actualizado a: $actionLabel'),
                      backgroundColor: AppTheme.available,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.unavailable,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';
    final reservationsAsync = ref.watch(reservationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Control de Préstamos' : 'Mis Reservas Activas'),
        elevation: 0,
      ),
      body: SafeArea(
        child: reservationsAsync.when(
          data: (list) {
            // Filtrar solo las pendientes o en uso
            final activeList = list.where(
              (res) => res.status == ReservationStatus.pending || 
                       res.status == ReservationStatus.active
            ).toList();

            if (activeList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdmin ? Icons.assignment_rounded : Icons.qr_code_scanner_rounded,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAdmin ? 'No hay préstamos activos' : 'No tienes reservas activas',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAdmin
                            ? 'Los préstamos entregados o pendientes aparecerán en este panel.'
                            : 'Explora el catálogo y reserva herramientas o laptops en segundos.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: activeList.length,
              itemBuilder: (context, index) {
                final reservation = activeList[index];
                return ReservationCard(
                  reservation: reservation,
                  onQrTap: isAdmin
                      ? null
                      : () {
                          context.push('/reservations/qr/${reservation.id}');
                        },
                  onCancel: isAdmin
                      ? null
                      : () => _confirmCancel(
                            context, 
                            ref, 
                            reservation.id, 
                            reservation.equipment.name
                          ),
                  onDeliver: isAdmin
                      ? () => _updateStatus(context, ref, reservation.id, ReservationStatus.active, 'entregado')
                      : null,
                  onReturn: isAdmin
                      ? () => _updateStatus(context, ref, reservation.id, ReservationStatus.completed, 'devuelto')
                      : null,
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error al cargar reservas: $err'),
          ),
        ),
      ),
    );
  }
}
