// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyModel {
  Timestamp? createdAt;
  String? symbol;
  String? code;
  bool? enable;
  bool? symbolAtRight;
  String? name;
  Map<String, String>? nameTranslations;
  int? decimalDigits;
  String? id;
  Timestamp? updatedAt;

  CurrencyModel({this.createdAt, this.symbol, this.code, this.enable, this.symbolAtRight, this.name, this.nameTranslations, this.decimalDigits, this.id, this.updatedAt});

  CurrencyModel.fromJson(Map<String, dynamic> json) {
    createdAt = json['createdAt'];
    symbol = json['symbol'];
    code = json['code'];
    enable = json['enable'];
    symbolAtRight = json['symbolAtRight'];
    final rawName = json['name'];
    if (rawName is Map) {
      nameTranslations = <String, String>{};
      Map<String, dynamic>.from(rawName).forEach((k, v) {
        if (v is String) nameTranslations![k] = v;
      });
      name = (nameTranslations!['default'] ?? '').isNotEmpty
          ? nameTranslations!['default']
          : (nameTranslations!['en'] ?? '');
    } else {
      name = rawName is String ? rawName : null;
    }
    decimalDigits = json['decimalDigits'] != null ? int.parse(json['decimalDigits'].toString()) : 2;
    id = json['id'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['createdAt'] = createdAt;
    data['symbol'] = symbol;
    data['code'] = code;
    data['enable'] = enable;
    data['symbolAtRight'] = symbolAtRight;
    data['name'] = (nameTranslations != null && nameTranslations!.isNotEmpty) ? nameTranslations : name;
    data['decimalDigits'] = decimalDigits;
    data['id'] = id;
    data['updatedAt'] = updatedAt;
    return data;
  }

  /// Localised currency name — requested → `default` → `en` → flat.
  String nameFor(String? code) => _localizedLookup(nameTranslations, code, name);

  static String _localizedLookup(Map<String, String>? map, String? code, String? fallback) {
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return fallback ?? '';
  }
}
