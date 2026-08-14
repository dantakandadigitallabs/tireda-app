class LanguageModel {
  String? id;

  /// Default-language name. See [nameFor] for a localised read.
  /// Firestore `name` accepts both flat String (legacy) and `Map<code, String>`.
  String? name;
  Map<String, String>? translations;

  String? code;
  bool? active;
  bool? defaultLanguage;

  LanguageModel({this.id, this.name, this.translations, this.code, this.active, this.defaultLanguage});

  @override
  String toString() {
    return 'LanguageModel{id: $id, name: $name, code: $code, active: $active, defaultLanguage:$defaultLanguage}';
  }

  LanguageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    final raw = json['name'];
    if (raw is Map) {
      translations = <String, String>{};
      Map<String, dynamic>.from(raw).forEach((k, v) {
        if (v is String) translations![k] = v;
      });
      name = (translations!['default'] ?? '').isNotEmpty
          ? translations!['default']
          : (translations!['en'] ?? '');
    } else {
      name = raw is String ? raw : null;
    }
    active = json['active'];
    defaultLanguage = json['defaultLanguage'];
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = (translations != null && translations!.isNotEmpty) ? translations : name;
    data['active'] = active;
    data['defaultLanguage'] = defaultLanguage;
    data['code'] = code;
    return data;
  }

  /// Localised name for [code].
  String nameFor(String? code) {
    if (translations != null && code != null && (translations![code] ?? '').isNotEmpty) return translations![code]!;
    if (translations != null && (translations!['default'] ?? '').isNotEmpty) return translations!['default']!;
    if (translations != null && (translations!['en'] ?? '').isNotEmpty) return translations!['en']!;
    return name ?? '';
  }
}
