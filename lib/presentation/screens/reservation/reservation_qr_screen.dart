import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lab_control_app/config/helpers/date_formatter.dart';
import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/providers/reservation_provider.dart';
import 'package:lab_control_app/presentation/providers/auth_provider.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class ReservationQrScreen extends ConsumerStatefulWidget {
  final String reservationId;

  const ReservationQrScreen({
    super.key,
    required this.reservationId,
  });

  @override
  ConsumerState<ReservationQrScreen> createState() => _ReservationQrScreenState();
}

class _ReservationQrScreenState extends ConsumerState<ReservationQrScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Polling cada 2 segundos para escuchar cambios en tiempo real
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkStatusUpdate();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _checkStatusUpdate() {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      ref.read(reservationProvider.notifier).loadReservations(authState.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de la Reserva'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
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
            final resIndex = list.indexWhere((r) => r.id == widget.reservationId);
            if (resIndex == -1) {
              return const Center(child: Text('Reserva no encontrada'));
            }
            final reservation = list[resIndex];

            // Si el estado ya es activo (entregado)
            if (reservation.status == ReservationStatus.active) {
              return _buildSuccessScreen(
                icon: Icons.check_circle_rounded,
                iconColor: AppTheme.primary,
                title: '¡Préstamo Entregado!',
                subtitle: 'El encargado del laboratorio ha confirmado la entrega del equipo.',
                reservation: reservation,
              );
            }

            // Si el estado es completado (devuelto)
            if (reservation.status == ReservationStatus.completed) {
              return _buildSuccessScreen(
                icon: Icons.assignment_turned_in_rounded,
                iconColor: Colors.blue.shade700,
                title: '¡Devolución Recibida!',
                subtitle: 'El equipo ha sido devuelto al laboratorio e ingresado al inventario con éxito.',
                reservation: reservation,
              );
            }

            // Vista por defecto (Pendiente): Código QR
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

  Widget _buildSuccessScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required dynamic reservation,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono Animado / Grande de éxito
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 90,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Título
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtítulo descritivo
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Resumen de datos en el éxito
            Card(
              elevation: 0,
              color: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildDetailRow('Equipo', reservation.equipment.name),
                    const SizedBox(height: 8),
                    _buildDetailRow('Cantidad', '${reservation.quantity} unidades'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Ubicación', reservation.equipment.location),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Retorno', 
                      DateFormatter.formatDateTime(reservation.returnDate)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Botón Entendido
            CustomButton(
              text: 'Entendido',
              width: double.infinity,
              onPressed: () => context.go('/reservations'),
            ),
          ],
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
