import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  String? id;
  String? title;
  Map<String, String>? titleTranslations;
  String? image;
  String? redirectType;
  String? redirectValue;
  String? redirectLabel;
  bool? active;
  int? sortOrder;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  BannerModel({
    this.id,
    this.title,
    this.titleTranslations,
    this.image,
    this.redirectType,
    this.redirectValue,
    this.redirectLabel,
    this.active,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  BannerModel.fromJson(Map<String, dynamic> json) {
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
    image = json['image'];
    redirectType = json['redirectType'];
    redirectValue = json['redirectValue'];
    redirectLabel = json['redirectLabel'];
    active = json['active'] ?? false;
    sortOrder = json['sortOrder'] ?? 0;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': (titleTranslations != null && titleTranslations!.isNotEmpty) ? titleTranslations : title,
      'image': image,
      'redirectType': redirectType,
      'redirectValue': redirectValue,
      'redirectLabel': redirectLabel,
      'active': active ?? false,
      'sortOrder': sortOrder ?? 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Localised title — requested → `default` → `en` → flat.
  String titleFor(String? code) => _localizedLookup(titleTranslations, code, title);

  static String _localizedLookup(Map<String, String>? map, String? code, String? fallback) {
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return fallback ?? '';
  }
}
