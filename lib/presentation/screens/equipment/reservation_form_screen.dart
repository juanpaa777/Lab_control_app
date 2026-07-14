import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/helpers/date_formatter.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/providers/equipment_provider.dart';
import 'package:lab_control_app/presentation/providers/reservation_provider.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const ReservationFormScreen({
    super.key,
    required this.equipmentId,
  });

  @override
  ConsumerState<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int _quantity = 1;
  DateTime? _pickupDateTime;
  DateTime? _returnDateTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Fechas por defecto sugeridas
    final now = DateTime.now();
    // Sugerir recogida en 30 minutos, redondeado
    _pickupDateTime = now.add(const Duration(minutes: 30));
    // Sugerir devolución en 2 horas
    _returnDateTime = _pickupDateTime!.add(const Duration(hours: 2));
  }

  Future<void> _selectDateTime(BuildContext context, bool isPickup) async {
    final now = DateTime.now();
    final initialDate = isPickup 
        ? (_pickupDateTime ?? now) 
        : (_returnDateTime ?? (_pickupDateTime ?? now).add(const Duration(hours: 1)));

    // 1. Seleccionar Fecha
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)), // Permitir hoy
      lastDate: now.add(const Duration(days: 30)),     // Límite 30 días
      locale: const Locale('es', 'ES'),
    );

    if (date == null) return;

    if (!context.mounted) return;

    // 2. Seleccionar Hora
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isPickup) {
        _pickupDateTime = selectedDateTime;
        // Si la devolución queda antes de la recogida, actualizarla
        if (_returnDateTime != null && !_returnDateTime!.isAfter(_pickupDateTime!)) {
          _returnDateTime = _pickupDateTime!.add(const Duration(hours: 2));
        }
      } else {
        _returnDateTime = selectedDateTime;
      }
    });
  }

  void _submit(dynamic equipment) async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupDateTime == null || _returnDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona las fechas de recogida y devolución'),
          backgroundColor: AppTheme.unavailable,
        ),
      );
      return;
    }

    // Validaciones locales adicionales en UI para feedback rápido
    final now = DateTime.now();
    if (_pickupDateTime!.isBefore(now.subtract(const Duration(minutes: 5)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de recogida no puede estar en el pasado'),
          backgroundColor: AppTheme.unavailable,
        ),
      );
      return;
    }

    if (!_returnDateTime!.isAfter(_pickupDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La devolución debe ser posterior a la recogida'),
          backgroundColor: AppTheme.unavailable,
        ),
      );
      return;
    }

    if (_quantity > equipment.availableUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay suficientes unidades disponibles (${equipment.availableUnits})'),
          backgroundColor: AppTheme.unavailable,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reservation = await ref.read(reservationProvider.notifier).makeReservation(
        equipmentId: widget.equipmentId,
        quantity: _quantity,
        pickupDate: _pickupDateTime!,
        returnDate: _returnDateTime!,
      );

      if (mounted) {
        // Redirigir a la pantalla de QR de la nueva reserva
        context.go('/reservations/qr/${reservation.id}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reserva creada! Código QR generado.'),
            backgroundColor: AppTheme.available,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.unavailable,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentListAsync = ref.watch(equipmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud de Reserva'),
      ),
      body: SafeArea(
        child: equipmentListAsync.when(
          data: (list) {
            final equipmentIndex = list.indexWhere((eq) => eq.id == widget.equipmentId);
            if (equipmentIndex == -1) {
              return const Center(child: Text('Equipo no encontrado'));
            }
            final equipment = list[equipmentIndex];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen del Equipo a reservar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Disponibles: ${equipment.availableUnits} unidades',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: equipment.availableUnits > 0 ? AppTheme.available : AppTheme.unavailable,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Selector de Cantidad
                    const Text(
                      'Cantidad a reservar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1 
                                    ? () => setState(() => _quantity--) 
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _quantity < equipment.availableUnits
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Máximo: ${equipment.availableUnits} u.',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Fecha/Hora Recogida
                    const Text(
                      'Fecha y hora de recogida',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateTime(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _pickupDateTime == null 
                                  ? 'Selecciona fecha y hora' 
                                  : DateFormatter.formatDateTime(_pickupDateTime!),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.calendar_month_outlined, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fecha/Hora Devolución
                    const Text(
                      'Fecha y hora de devolución',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateTime(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _returnDateTime == null 
                                  ? 'Selecciona fecha y hora' 
                                  : DateFormatter.formatDateTime(_returnDateTime!),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.calendar_month_outlined, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    // Botones de acción
                    CustomButton(
                      text: 'Confirmar Reserva',
                      width: double.infinity,
                      isLoading: _isSubmitting,
                      onPressed: () => _submit(equipment),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error al cargar formulario: $err'),
          ),
        ),
      ),
    );
  }
}
