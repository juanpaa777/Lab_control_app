import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/config/helpers/date_formatter.dart';
import 'package:lab_control_app/config/helpers/reservation_status_helper.dart';
import 'package:lab_control_app/domain/entities/reservation.dart';
import 'package:lab_control_app/presentation/providers/reservation_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _hasScanned = false; // Evita lecturas dobles consecutivas

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.startsWith('labcontrol-res-')) {
        // Vibrar levemente para notificar al usuario física y auditivamente
        HapticFeedback.lightImpact();
        setState(() {
          _hasScanned = true;
        });
        
        _processScannedCode(rawValue);
        break;
      }
    }
  }

  void _processScannedCode(String qrCodeValue) {
    // Buscar la reserva en la lista cargada en el provider
    final reservationsState = ref.read(reservationProvider);
    
    reservationsState.when(
      data: (list) {
        // Buscar coincidencia por el código QR
        final index = list.indexWhere((res) => res.qrCode == qrCodeValue);
        
        if (index == -1) {
          _showErrorBottomSheet('El código QR no coincide con ninguna reserva activa o pendiente.');
        } else {
          _showReservationDetails(list[index]);
        }
      },
      loading: () => _showErrorBottomSheet('Las reservas se están cargando. Reintenta en un momento.'),
      error: (err, _) => _showErrorBottomSheet('Error al consultar las reservas locales: $err'),
    );
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.unavailable,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Código Inválido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reintentar Escaneo'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Al cerrar el modal, reactivar el escaneo
      setState(() {
        _hasScanned = false;
      });
    });
  }

  void _showReservationDetails(Reservation reservation) {
    final bool isPending = reservation.status == ReservationStatus.pending;
    final bool isActive = reservation.status == ReservationStatus.active;
    
    // Determinar siguiente estado y etiqueta del botón
    ReservationStatus? nextStatus;
    String btnText = '';
    Color btnColor = AppTheme.primary;
    
    if (isPending) {
      nextStatus = ReservationStatus.active;
      btnText = 'Entregar Equipo (Iniciar Préstamo)';
      btnColor = AppTheme.primary;
    } else if (isActive) {
      nextStatus = ReservationStatus.completed;
      btnText = 'Recibir Equipo (Finalizar Préstamo)';
      btnColor = Colors.blue.shade700;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.8,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Detalles del Préstamo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tarjeta del estudiante
                  Card(
                    color: AppTheme.background,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: const Icon(Icons.person_rounded, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.userName ?? 'Estudiante',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Matrícula: ${reservation.studentId ?? "N/A"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Información del equipo
                  _buildInfoRow('Equipo:', reservation.equipment.name, isBold: true),
                  _buildInfoRow('Código:', reservation.equipment.code),
                  _buildInfoRow('Cantidad:', '${reservation.quantity} unidades'),
                  _buildInfoRow('Recogida:', DateFormatter.formatDateTime(reservation.pickupDate)),
                  _buildInfoRow('Devolución:', DateFormatter.formatDateTime(reservation.returnDate)),
                  const SizedBox(height: 20),
                  
                  // Botones de acción
                  if (nextStatus != null) ...[
                    ElevatedButton(
                      onPressed: () async {
                        // Cerrar modal
                        Navigator.pop(context);
                        _applyStatusChange(reservation.id, nextStatus!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        btnText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Esta reserva ya ha sido devuelta o cancelada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Reactivar escaneo al cerrar
      setState(() {
        _hasScanned = false;
      });
    });
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyStatusChange(String reservationId, ReservationStatus nextStatus) async {
    // Mostrar cargando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );

    try {
      await ref.read(reservationProvider.notifier).updateStatus(reservationId, nextStatus);
      
      if (!mounted) return;
      Navigator.pop(context); // Quitar cargando

      // Mostrar confirmación de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == ReservationStatus.active 
                ? 'Préstamo iniciado. Equipo entregado con éxito.' 
                : 'Devolución registrada. Inventario restaurado.'
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
      
      // Salir de la pantalla del escáner
      context.pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Quitar cargando
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.unavailable,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR de Alumno', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón del Flash
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off_rounded);
                  case TorchState.on:
                    return const Icon(Icons.flash_on_rounded, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off_rounded);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Botón de rotar cámara
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Lector de la cámara
          MobileScanner(
            controller: _controller,
            onDetect: _onQrDetected,
          ),
          
          // Overlay visual del visor del QR (caja transparente con bordes verdes)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
          
          // Instrucciones flotantes
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Alinea el código QR del alumno dentro del recuadro para registrar la entrega o devolución.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
