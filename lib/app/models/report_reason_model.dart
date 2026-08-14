import 'package:cloud_firestore/cloud_firestore.dart';

class ReportReasonModel {
  String? id;

  /// Default-language title. See [titleFor] for localised reads.
  /// Firestore `title` accepts both flat String (legacy) and Map<code, String>.
  String? title;
  Map<String, String>? titleTranslations;

  String? description;
  Map<String, String>? descriptionTranslations;

  bool? active;
  int? sortOrder;
  Timestamp? createdAt;

  ReportReasonModel({
    this.id,
    this.title,
    this.titleTranslations,
    this.description,
    this.descriptionTranslations,
    this.active,
    this.sortOrder,
    this.createdAt,
  });

  ReportReasonModel.fromJson(Map<String, dynamic> json) {
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
    active = json['active'] ?? true;
    sortOrder = json['sortOrder'] ?? 0;
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': (titleTranslations != null && titleTranslations!.isNotEmpty) ? titleTranslations : title,
      'description': (descriptionTranslations != null && descriptionTranslations!.isNotEmpty) ? descriptionTranslations : description,
      'active': active ?? true,
      'sortOrder': sortOrder ?? 0,
      'createdAt': createdAt,
    };
  }

  /// Localised title / description for [code] — requested → `default` → `en` → flat.
  String titleFor(String? code) => _lookup(titleTranslations, code, title);
  String descriptionFor(String? code) => _lookup(descriptionTranslations, code, description);

  static String _lookup(Map<String, String>? m, String? c, String? f) {
    if (m != null && c != null && (m[c] ?? '').isNotEmpty) return m[c]!;
    if (m != null && (m['default'] ?? '').isNotEmpty) return m['default']!;
    if (m != null && (m['en'] ?? '').isNotEmpty) return m['en']!;
    return f ?? '';
  }
}
