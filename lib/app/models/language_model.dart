class LanguageModel {
  String? id;
  String? name;
  String? code;
  bool? active;
  bool? defaultLanguage;

  LanguageModel({this.id, this.name, this.code, this.active, this.defaultLanguage});

  @override
  String toString() {
    return 'LanguageModel{id: $id, name: $name, code: $code, active: $active, defaultLanguage:$defaultLanguage}';
  }

  LanguageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    active = json['active'];
    defaultLanguage = json['defaultLanguage'];
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['active'] = active;
    data['defaultLanguage'] = defaultLanguage;
    data['code'] = code;
    return data;
  }
}
