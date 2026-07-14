import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/providers/equipment_provider.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class EquipmentDetailScreen extends ConsumerWidget {
  final String equipmentId;

  const EquipmentDetailScreen({
    super.key,
    required this.equipmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentListAsync = ref.watch(equipmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Equipo'),
      ),
      body: SafeArea(
        child: equipmentListAsync.when(
          data: (list) {
            final equipmentIndex = list.indexWhere((eq) => eq.id == equipmentId);
            if (equipmentIndex == -1) {
              return const Center(child: Text('Equipo no encontrado'));
            }
            final equipment = list[equipmentIndex];

            // Determinar color de estado y disponibilidad
            Color statusColor;
            String statusLabel;
            bool isBtnEnabled = equipment.availableUnits > 0;
            
            if (equipment.availableUnits == 0) {
              statusColor = AppTheme.unavailable;
              statusLabel = 'No disponible';
            } else if (equipment.availableUnits <= 2) {
              statusColor = AppTheme.warning;
              statusLabel = 'Pocas unidades (${equipment.availableUnits} de ${equipment.totalUnits} disp.)';
            } else {
              statusColor = AppTheme.available;
              statusLabel = 'Disponible (${equipment.availableUnits} de ${equipment.totalUnits} disp.)';
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen / Icono ilustrativo grande
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: (equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                equipment.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getCategoryIcon(equipment.category.name),
                                    size: 80,
                                    color: AppTheme.primary,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              _getCategoryIcon(equipment.category.name),
                              size: 80,
                              color: AppTheme.primary,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre y Código
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          equipment.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          equipment.code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Categoría
                  Text(
                    'Categoría: ${equipment.category.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estado de disponibilidad
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 16),

                  // Ubicación del Laboratorio
                  const Text(
                    'Ubicación de Recogida',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment.location,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Debes presentarte en este laboratorio con tu código QR generado para recoger el equipo.',
                                  style: TextStyle(
                                    fontSize: 11,
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

                  const Spacer(),

                  // Botón Reservar
                  CustomButton(
                    text: isBtnEnabled ? 'Reservar Equipo' : 'Sin disponibilidad',
                    width: double.infinity,
                    onPressed: isBtnEnabled
                        ? () => context.push('/home/equipment/$equipmentId/reserve')
                        : null,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error al cargar detalle: $err'),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'computación':
      case 'cómputo':
        return Icons.laptop_chromebook_rounded;
      case 'redes':
        return Icons.router_rounded;
      case 'electrónica':
      default:
        return Icons.developer_board_rounded;
    }
  }
}
