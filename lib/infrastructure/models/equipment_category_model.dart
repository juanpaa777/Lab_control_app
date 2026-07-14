class EquipmentCategoryModel {
  final String id;
  final String name;

  EquipmentCategoryModel({
    required this.id,
    required this.name,
  });

  factory EquipmentCategoryModel.fromJson(Map<String, dynamic> json) {
    return EquipmentCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
