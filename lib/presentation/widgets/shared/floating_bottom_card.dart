import 'package:flutter/material.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';

/// Un contenedor flotante para botones de acción en la parte inferior de la pantalla.
/// Queda totalmente suspendido e independiente del borde inferior con márgenes amplios, bordes redondeados y sombra.
class FloatingBottomCard extends StatelessWidget {
  final Widget child;
  final double horizontalMargin;
  final double bottomMargin;
  final EdgeInsetsGeometry padding;

  const FloatingBottomCard({
    super.key,
    required this.child,
    this.horizontalMargin = 20.0,
    this.bottomMargin = 28.0,
    this.padding = const EdgeInsets.all(12.0),
  });

  @override
  Widget build(BuildContext context) {
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    // Asegurar elevación física amplia (mínimo 32px + safe area del sistema)
    final effectiveBottomMargin = bottomMargin + (systemBottomPadding > 0 ? systemBottomPadding : 16.0);

    return Container(
      margin: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: effectiveBottomMargin,
        top: 8.0,
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
