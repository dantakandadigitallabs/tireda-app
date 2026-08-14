// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';

/// Onboarding screen configured from the admin panel (`onboarding_screens`
/// collection). `title`/`description` accept both a flat String (legacy)
/// and a `Map<code, String>` written by the multi-language admin.
class OnBoardingModel {
  String? id;

  String? title;
  Map<String, String>? titleTranslations;

  String? description;
  Map<String, String>? descriptionTranslations;

  String? type;
  String? image;
  bool? active;
  int? sortOrder;
  Timestamp? createdAt;

  OnBoardingModel({
    this.id,
    this.title,
    this.titleTranslations,
    this.description,
    this.descriptionTranslations,
    this.type,
    this.image,
    this.active,
    this.sortOrder,
    this.createdAt,
  });

  OnBoardingModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    final t = _readField(json['title']);
    title = t.$1;
    titleTranslations = t.$2;
    final d = _readField(json['description']);
    description = d.$1;
    descriptionTranslations = d.$2;
    type = json['type'];
    image = json['image'];
    active = json['active'] ?? false;
    sortOrder = json['sortOrder'] ?? 0;
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': (titleTranslations != null && titleTranslations!.isNotEmpty) ? titleTranslations : title,
      'description': (descriptionTranslations != null && descriptionTranslations!.isNotEmpty) ? descriptionTranslations : description,
      'type': type,
      'image': image,
      'active': active ?? false,
      'sortOrder': sortOrder ?? 0,
      'createdAt': createdAt,
    };
  }

  /// Localised title / description: requested → `default` → `en` → flat.
  String titleFor(String? code) => _lookup(titleTranslations, code, title);
  String descriptionFor(String? code) => _lookup(descriptionTranslations, code, description);

  static (String?, Map<String, String>?) _readField(dynamic raw) {
    if (raw is Map) {
      final map = <String, String>{};
      Map<String, dynamic>.from(raw).forEach((k, v) {
        if (v is String) map[k] = v;
      });
      return (_extractDefault(map), map);
    }
    if (raw is String) return (raw, null);
    return (null, null);
  }

  static String _extractDefault(Map<String, String> map) {
    if ((map['default'] ?? '').isNotEmpty) return map['default']!;
    if ((map['en'] ?? '').isNotEmpty) return map['en']!;
    for (final v in map.values) {
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static String _lookup(Map<String, String>? map, String? code, String? fallback) {
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return fallback ?? '';
  }
}
