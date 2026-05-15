import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureSectionModel {
  String? id;
  String? title;
  String? description;
  String? slug;
  String? filterType;
  int? styleIndex;
  double? minPrice;
  double? maxPrice;
  String? categoryId;
  String? categoryName;
  List<String>? categoryPath;
  List<String>? categoryNamePath;
  int? maxRecords;
  bool? active;
  int? sortOrder;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  FeatureSectionModel({
    this.id,
    this.title,
    this.description,
    this.slug,
    this.filterType,
    this.styleIndex,
    this.minPrice,
    this.maxPrice,
    this.categoryId,
    this.categoryName,
    this.categoryPath,
    this.categoryNamePath,
    this.maxRecords,
    this.active,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  FeatureSectionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    slug = json['slug'];
    filterType = json['filterType'];
    styleIndex = json['styleIndex'] != null ? (json['styleIndex'] as num).toInt() : 0;
    minPrice = json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : null;
    maxPrice = json['maxPrice'] != null ? (json['maxPrice'] as num).toDouble() : null;
    categoryId = json['categoryId'];
    categoryName = json['categoryName'];
    categoryPath = json['categoryPath'] != null ? List<String>.from(json['categoryPath']) : [];
    categoryNamePath = json['categoryNamePath'] != null ? List<String>.from(json['categoryNamePath']) : [];
    maxRecords = json['maxRecords'] != null ? (json['maxRecords'] as num).toInt() : 10;
    active = json['active'] ?? false;
    sortOrder = json['sortOrder'] != null ? (json['sortOrder'] as num).toInt() : 0;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'slug': slug,
      'filterType': filterType,
      'styleIndex': styleIndex ?? 0,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryPath': categoryPath ?? [],
      'categoryNamePath': categoryNamePath ?? [],
      'maxRecords': maxRecords ?? 10,
      'active': active ?? false,
      'sortOrder': sortOrder ?? 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
