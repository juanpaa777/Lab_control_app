import 'equipment_category_model.dart';

class EquipmentModel {
  final String id;
  final String name;
  final EquipmentCategoryModel category;
  final String code;
  final String location;
  final int totalUnits;
  final int availableUnits;
  final String? imageUrl;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.code,
    required this.location,
    required this.totalUnits,
    required this.availableUnits,
    this.imageUrl,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: EquipmentCategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      code: json['code'] as String,
      location: json['location'] as String,
      totalUnits: json['totalUnits'] as int,
      availableUnits: json['availableUnits'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.toJson(),
      'code': code,
      'location': location,
      'totalUnits': totalUnits,
      'availableUnits': availableUnits,
      'imageUrl': imageUrl,
    };
  }
}
