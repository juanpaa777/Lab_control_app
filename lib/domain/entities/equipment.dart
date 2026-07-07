import 'equipment_category.dart';

class Equipment {
  final String id;
  final String name;
  final EquipmentCategory category;
  final String code;
  final String location;
  final int totalUnits;
  final int availableUnits;
  final String? imageUrl;

  const Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.code,
    required this.location,
    required this.totalUnits,
    required this.availableUnits,
    this.imageUrl,
  });

  bool get isAvailable => availableUnits > 0;

  Equipment copyWith({
    String? id,
    String? name,
    EquipmentCategory? category,
    String? code,
    String? location,
    int? totalUnits,
    int? availableUnits,
    String? imageUrl,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      code: code ?? this.code,
      location: location ?? this.location,
      totalUnits: totalUnits ?? this.totalUnits,
      availableUnits: availableUnits ?? this.availableUnits,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
