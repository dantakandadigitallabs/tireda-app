import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationDocumentModel {
  String? id;

  /// Default-language name. See [nameFor] for a localised read.
  /// Firestore accepts flat String (legacy) or `Map<code, String>`.
  String? name;
  Map<String, String>? nameTranslations;

  String? description;
  Map<String, String>? descriptionTranslations;

  String? type; // 'file', 'image', 'textfield'
  String? imageSides; // 'one', 'two' (only for type == 'image')
  bool? isRequired;
  bool? active;
  int? order;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  VerificationDocumentModel({
    this.id,
    this.name,
    this.nameTranslations,
    this.description,
    this.descriptionTranslations,
    this.type,
    this.imageSides,
    this.isRequired,
    this.active,
    this.order,
    this.createdAt,
    this.updatedAt,
  });

  VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    final n = _readTranslation(json['name']);
    name = n.$1;
    nameTranslations = n.$2;
    final d = _readTranslation(json['description']);
    description = d.$1;
    descriptionTranslations = d.$2;
    type = json['type'];
    imageSides = json['imageSides'];
    isRequired = json['isRequired'];
    active = json['active'];
    order = json['order'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': (nameTranslations != null && nameTranslations!.isNotEmpty) ? nameTranslations : name,
      'description': (descriptionTranslations != null && descriptionTranslations!.isNotEmpty) ? descriptionTranslations : description,
      'type': type,
      'imageSides': imageSides,
      'isRequired': isRequired,
      'active': active,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Localised name / description — requested → `default` → `en` → flat.
  String nameFor(String? code) => _localizedLookup(nameTranslations, code, name);
  String descriptionFor(String? code) => _localizedLookup(descriptionTranslations, code, description);

  static (String?, Map<String, String>?) _readTranslation(dynamic raw) {
    if (raw is Map) {
      final map = <String, String>{};
      Map<String, dynamic>.from(raw).forEach((k, v) {
        if (v is String) map[k] = v;
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

  static String _localizedLookup(Map<String, String>? map, String? code, String? fallback) {
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return fallback ?? '';
  }
}
