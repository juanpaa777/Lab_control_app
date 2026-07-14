import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/domain/entities/equipment.dart';
import 'package:lab_control_app/presentation/providers/equipment_provider.dart';
import 'package:lab_control_app/presentation/widgets/shared/custom_button.dart';

class EquipmentFormScreen extends ConsumerStatefulWidget {
  final String? equipmentId;

  const EquipmentFormScreen({
    super.key,
    this.equipmentId,
  });

  @override
  ConsumerState<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends ConsumerState<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _totalUnitsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String? _selectedCategoryId;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _totalUnitsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _initFields(Equipment equipment) {
    if (_isInitialized) return;
    _nameController.text = equipment.name;
    _codeController.text = equipment.code;
    _locationController.text = equipment.location;
    _totalUnitsController.text = equipment.totalUnits.toString();
    _imageUrlController.text = equipment.imageUrl ?? '';
    _selectedCategoryId = equipment.category.id;
    _isInitialized = true;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una categoría'),
          backgroundColor: AppTheme.unavailable,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final location = _locationController.text.trim();
    final totalUnits = int.parse(_totalUnitsController.text);
    final imageUrl = _imageUrlController.text.trim();

    try {
      if (widget.equipmentId == null) {
        // Crear
        await ref.read(equipmentListProvider.notifier).createEquipment(
          name: name,
          categoryId: _selectedCategoryId!,
          code: code,
          location: location,
          totalUnits: totalUnits,
          imageUrl: imageUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipo agregado exitosamente al inventario'),
              backgroundColor: AppTheme.available,
            ),
          );
          context.pop();
        }
      } else {
        // Editar
        await ref.read(equipmentListProvider.notifier).updateEquipment(
          id: widget.equipmentId!,
          name: name,
          categoryId: _selectedCategoryId!,
          code: code,
          location: location,
          totalUnits: totalUnits,
          imageUrl: imageUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipo actualizado exitosamente'),
              backgroundColor: AppTheme.available,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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
    final isEditMode = widget.equipmentId != null;
    final categoriesAsync = ref.watch(categoriesProvider);

    // Si estamos en modo edición, precargar datos de la lista de equipos existente
    if (isEditMode) {
      ref.watch(equipmentListProvider).whenData((list) {
        final equipmentIndex = list.indexWhere((eq) => eq.id == widget.equipmentId);
        if (equipmentIndex != -1) {
          _initFields(list[equipmentIndex]);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Editar Equipo' : 'Nuevo Equipo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditMode ? 'Actualizar Información' : 'Registrar Nuevo Equipo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa los datos del equipo para agregarlo o actualizarlo en el catálogo.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Campo Nombre
                const Text(
                  'Nombre del Equipo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Osciloscopio Digital Tektronix',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa el nombre del equipo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fila de Código y Categoría
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Código
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Código Único',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              hintText: 'EQ-005',
                              prefixIcon: Icon(Icons.qr_code_scanner_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Ingresa un código';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Categoría
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categoría',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          categoriesAsync.when(
                            data: (categories) {
                              return DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                hint: const Text('Seleccionar'),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                ),
                                items: categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(
                                      cat.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategoryId = val;
                                  });
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const Text('Error al cargar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila de Ubicación y Stock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ubicación
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubicación Física',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Laboratorio 3',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Ingresa la ubicación';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Stock Total
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stock Total',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _totalUnitsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '10',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Requerido';
                              final num = int.tryParse(value);
                              if (num == null || num < 0) return 'Mayor o igual a 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // URL de Imagen
                const Text(
                  'URL de la Imagen (Opcional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://ejemplo.com/imagen.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 40),

                CustomButton(
                  text: isEditMode ? 'Guardar Cambios' : 'Registrar Equipo',
                  width: double.infinity,
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
