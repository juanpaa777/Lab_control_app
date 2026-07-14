import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lab_control_app/config/helpers/date_formatter.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/providers/reservation_provider.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class ReservationQrScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationQrScreen({
    super.key,
    required this.reservationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR de Recogida'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // Ir de regreso a la lista de reservas
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reservations');
            }
          },
        ),
      ),
      body: SafeArea(
        child: reservationsAsync.when(
          data: (list) {
            final resIndex = list.indexWhere((r) => r.id == reservationId);
            if (resIndex == -1) {
              return const Center(child: Text('Reserva no encontrada'));
            }
            final reservation = list[resIndex];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Tarjeta del QR
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        children: [
                          const Text(
                            'Presenta este código en el laboratorio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El encargado del laboratorio lo escaneará para entregarte el equipo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Generación del Código QR
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: reservation.qrCode,
                              version: QrVersions.auto,
                              size: 200.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.primaryDark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Código de la reserva
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              reservation.id.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resumen de la reserva
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Préstamo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          
                          // Equipo
                          _buildDetailRow('Equipo', reservation.equipment.name),
                          const SizedBox(height: 12),
                          
                          // Cantidad
                          _buildDetailRow(
                            'Cantidad', 
                            '${reservation.quantity} ${reservation.quantity == 1 ? "unidad" : "unidades"}'
                          ),
                          const SizedBox(height: 12),

                          // Ubicación
                          _buildDetailRow('Ubicación', reservation.equipment.location),
                          const SizedBox(height: 12),
                          
                          // Recogida
                          _buildDetailRow(
                            'Recogida', 
                            DateFormatter.formatDateTime(reservation.pickupDate)
                          ),
                          const SizedBox(height: 12),
                          
                          // Devolución
                          _buildDetailRow(
                            'Devolución', 
                            DateFormatter.formatDateTime(reservation.returnDate)
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón Volver
                  CustomButton(
                    text: 'Ir a Mis Reservas',
                    width: double.infinity,
                    onPressed: () => context.go('/reservations'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error al cargar QR: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
