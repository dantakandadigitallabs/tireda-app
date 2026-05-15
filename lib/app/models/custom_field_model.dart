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

  CustomFieldModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
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
    data['name'] = name;
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
}
