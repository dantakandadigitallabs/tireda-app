import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  String? id;

  /// Default-language category name. See [categoryNameFor] for a localised
  /// read. Firestore's `categoryName` field arrives as either a flat String
  /// (legacy) or a `Map<code, String>` (from the multi-language admin);
  /// both shapes are normalised on decode.
  String? categoryName;
  Map<String, String>? nameTranslations;

  String? description;
  Map<String, String>? descriptionTranslations;

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
    this.nameTranslations,
    this.description,
    this.descriptionTranslations,
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
    final n = _readTranslation(json['categoryName']);
    categoryName = n.$1;
    nameTranslations = n.$2;
    final d = _readTranslation(json['description']);
    description = d.$1;
    descriptionTranslations = d.$2;
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
    data['categoryName'] = (nameTranslations != null && nameTranslations!.isNotEmpty)
        ? nameTranslations
        : categoryName;
    data['description'] = (descriptionTranslations != null && descriptionTranslations!.isNotEmpty)
        ? descriptionTranslations
        : description;
    data['slug'] = slug;
    data['image'] = image;
    data['active'] = active;
    data['isJobCategory'] = isJobCategory;
    data['priceOptional'] = priceOptional;
    data['parentCategoryId'] = parentCategoryId;
    data['createdAt'] = createdAt;
    return data;
  }

  /// Localised category name — requested code → `default` → `en` → flat.
  String categoryNameFor(String? code) => _lookup(nameTranslations, code, categoryName);

  /// Localised description.
  String descriptionFor(String? code) => _lookup(descriptionTranslations, code, description);
}

(String?, Map<String, String>?) _readTranslation(dynamic raw) {
  if (raw is Map) {
    final map = <String, String>{};
    Map<String, dynamic>.from(raw).forEach((code, value) {
      if (value is String) map[code] = value;
      if (value is Map && value['name'] is String) map[code] = value['name'] as String;
    });
    String def = '';
    if ((map['default'] ?? '').isNotEmpty) {
      def = map['default']!;
    } else if ((map['en'] ?? '').isNotEmpty) {
      def = map['en']!;
    } else {
      for (final v in map.values) {
        if (v.isNotEmpty) {
          def = v;
          break;
        }
      }
    }
    return (def, map);
  }
  if (raw is String) return (raw, null);
  return (null, null);
}

String _lookup(Map<String, String>? map, String? code, String? fallback) {
  if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
  if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
  if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
  return fallback ?? '';
}
