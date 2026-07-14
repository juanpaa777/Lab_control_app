import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas Activas'),
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
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 64,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes reservas activas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Explora el catálogo y reserva herramientas o laptops en segundos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                  onQrTap: () {
                    context.push('/reservations/qr/${reservation.id}');
                  },
                  onCancel: () => _confirmCancel(
                    context, 
                    ref, 
                    reservation.id, 
                    reservation.equipment.name
                  ),
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
