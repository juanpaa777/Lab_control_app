import 'package:flutter/material.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';

enum ReservationStatus {
  pending,   // Pendiente de recogida (Código QR generado)
  active,    // Entregado / En uso
  completed, // Devuelto / Finalizado
  cancelled  // Cancelado
}

class ReservationStatusHelper {
  static String getLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.active:
        return 'En uso';
      case ReservationStatus.completed:
        return 'Devuelto';
      case ReservationStatus.cancelled:
        return 'Cancelado';
    }
  }

  static Color getColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppTheme.warning;
      case ReservationStatus.active:
        return AppTheme.primary;
      case ReservationStatus.completed:
        return AppTheme.available;
      case ReservationStatus.cancelled:
        return AppTheme.unavailable;
    }
  }

  static IconData getIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.qr_code_2_rounded;
      case ReservationStatus.active:
        return Icons.handyman_rounded;
      case ReservationStatus.completed:
        return Icons.check_circle_rounded;
      case ReservationStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }
}
