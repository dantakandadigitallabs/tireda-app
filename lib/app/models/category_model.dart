import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  String? id;
  String? categoryName;
  String? description;
  String? slug;
  String? image;
  bool? active;
  bool? isJobCategory;
  bool? priceOptional;
  String? parentCategoryId;
  Timestamp? createdAt;
  int? subCategoryCount;
  List<CategoryModel>? children;

  CategoryModel({
    this.id,
    this.categoryName,
    this.description,
    this.slug,
    this.image,
    this.active,
    this.isJobCategory,
    this.priceOptional,
    this.parentCategoryId,
    this.createdAt,
    this.subCategoryCount,
    this.children,
  });

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    categoryName = json['categoryName'];
    description = json['description'];
    slug = json['slug'];
    image = json['image'];
    active = json['active'] ?? false;
    isJobCategory = json['isJobCategory'] ?? false;
    priceOptional = json['priceOptional'] ?? false;
    parentCategoryId = json['parentCategoryId'];
    createdAt = json['createdAt'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['categoryName'] = categoryName;
    data['description'] = description;
    data['slug'] = slug;
    data['image'] = image;
    data['active'] = active;
    data['isJobCategory'] = isJobCategory;
    data['priceOptional'] = priceOptional;
    data['parentCategoryId'] = parentCategoryId;
    data['createdAt'] = createdAt;
    return data;
  }
}
