import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureSectionModel {
  String? id;
  String? title;
  Map<String, String>? titleTranslations;
  String? description;
  Map<String, String>? descriptionTranslations;
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
    this.titleTranslations,
    this.description,
    this.descriptionTranslations,
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
    final rawTitle = json['title'];
    if (rawTitle is Map) {
      titleTranslations = <String, String>{};
      Map<String, dynamic>.from(rawTitle).forEach((k, v) {
        if (v is String) titleTranslations![k] = v;
      });
      title = (titleTranslations!['default'] ?? '').isNotEmpty
          ? titleTranslations!['default']
          : (titleTranslations!['en'] ?? '');
    } else {
      title = rawTitle is String ? rawTitle : null;
    }
    final rawDesc = json['description'];
    if (rawDesc is Map) {
      descriptionTranslations = <String, String>{};
      Map<String, dynamic>.from(rawDesc).forEach((k, v) {
        if (v is String) descriptionTranslations![k] = v;
      });
      description = (descriptionTranslations!['default'] ?? '').isNotEmpty
          ? descriptionTranslations!['default']
          : (descriptionTranslations!['en'] ?? '');
    } else {
      description = rawDesc is String ? rawDesc : null;
    }
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
      'title': (titleTranslations != null && titleTranslations!.isNotEmpty) ? titleTranslations : title,
      'description': (descriptionTranslations != null && descriptionTranslations!.isNotEmpty) ? descriptionTranslations : description,
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

  /// Localised title / description for [code] — requested → `default` → `en` → flat.
  String titleFor(String? code) => _localizedLookup(titleTranslations, code, title);
  String descriptionFor(String? code) => _localizedLookup(descriptionTranslations, code, description);

  static String _localizedLookup(Map<String, String>? map, String? code, String? fallback) {
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return fallback ?? '';
  }
}
