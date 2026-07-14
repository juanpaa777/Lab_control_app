import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lab_control_app/config/theme/app_theme.dart';
import 'package:lab_control_app/presentation/providers/auth_provider.dart';
import 'package:lab_control_app/presentation/providers/equipment_provider.dart';
import 'package:lab_control_app/presentation/widgets/equipment/category_chip.dart';
import 'package:lab_control_app/presentation/widgets/equipment/equipment_card.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final filteredEquipment = ref.watch(filteredEquipmentProvider);
    final equipmentListAsync = ref.watch(equipmentListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Recargar datos locales
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(selectedCategoryIdProvider.notifier).state = null;
            _searchController.clear();
            await ref.read(equipmentListProvider.notifier).loadEquipment();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, ${user?.name ?? "Estudiante"}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '¿Qué equipo vas a necesitar hoy?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Text(
                              (user?.name ?? 'E').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Buscador
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          ref.read(searchQueryProvider.notifier).state = value;
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, código o ubicación...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchQueryProvider.notifier).state = '';
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sección Categorías
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (categories) {
                    return SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return CategoryChip(
                              label: 'Todos',
                              isSelected: selectedCategoryId == null,
                              onTap: () {
                                ref.read(selectedCategoryIdProvider.notifier).state = null;
                              },
                            );
                          }
                          final category = categories[index - 1];
                          return CategoryChip(
                            label: category.name,
                            isSelected: selectedCategoryId == category.id,
                            onTap: () {
                              ref.read(selectedCategoryIdProvider.notifier).state = category.id;
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 42,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Inventario de Equipos
              equipmentListAsync.when(
                data: (_) {
                  if (filteredEquipment.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron equipos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Intenta buscar con otros términos o filtros.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final equipment = filteredEquipment[index];
                          return EquipmentCard(
                            equipment: equipment,
                            onTap: () {
                              context.push('/home/equipment/${equipment.id}');
                            },
                          );
                        },
                        childCount: filteredEquipment.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Text('Error cargando catálogo: $e'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
