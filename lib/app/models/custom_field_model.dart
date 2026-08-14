import 'package:cloud_firestore/cloud_firestore.dart';

class CustomFieldModel {
  String? id;
  String? name;
  String? type;
  bool? required;
  bool? active;
  String? image;
  int? min;
  int? max;
  List<String>? options;
  List<String>? selectedCategories;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  String? categoryPath;
  List<String>? categoryPaths;

  CustomFieldModel({
    this.id,
    this.name,
    this.type,
    this.required,
    this.active,
    this.image,
    this.min,
    this.max,
    this.options,
    this.selectedCategories,
    this.createdAt,
    this.updatedAt,
    this.categoryPath,
    this.categoryPaths,
  });

  /// Optional per-language name map (see [nameFor]).
  /// Only populated when the admin wrote translations.
  Map<String, String>? nameTranslations;

  CustomFieldModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    final rawName = json['name'];
    if (rawName is Map) {
      nameTranslations = <String, String>{};
      Map<String, dynamic>.from(rawName).forEach((k, v) {
        if (v is String) nameTranslations![k] = v;
      });
      name = (nameTranslations!['default'] ?? '').isNotEmpty
          ? nameTranslations!['default']
          : (nameTranslations!['en'] ?? '');
    } else {
      name = rawName is String ? rawName : null;
    }
    type = json['type'];
    required = json['required'] ?? false;
    active = json['active'] ?? false;
    image = json['image'];
    min = json['min'];
    max = json['max'];
    options = json['options'] != null ? List<String>.from(json['options']) : null;
    selectedCategories = json['selectedCategories'] != null ? List<String>.from(json['selectedCategories']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = (nameTranslations != null && nameTranslations!.isNotEmpty)
        ? nameTranslations
        : name;
    data['type'] = type;
    data['required'] = required;
    data['active'] = active;
    data['image'] = image;
    data['min'] = min;
    data['max'] = max;
    data['options'] = options;
    data['selectedCategories'] = selectedCategories;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }

  /// Localised field name — requested code → `default` → `en` → flat.
  String nameFor(String? code) {
    final map = nameTranslations;
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return name ?? '';
  }
}
