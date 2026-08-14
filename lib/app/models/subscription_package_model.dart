import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPackageModel {
  String? id;
  String? image;
  Map<String, String>? name;
  String? type;
  String? categoryType;
  double? price;
  double? discountPercentage;
  double? finalPrice;
  int? packageDuration;
  bool? isUnlimited;
  bool? status;
  bool? isItemLimitUnlimited;
  int? itemLimit;
  String? listingDurationType;
  int? customDuration;

  /// Ready-to-render key points in the device's current language.
  /// Legacy `List<String>` docs load as-is; new docs where each item is
  /// `{ default, en, ar, ... }` are collapsed to a single string per row
  /// using the active locale (falls back default → en → first non-empty).
  List<String>? keyPoints;

  /// Raw per-language rows kept alongside [keyPoints] so consumers that
  /// want a specific language (e.g. server-triggered emails) can look
  /// them up via [keyPointsFor] without waiting on the current locale.
  List<Map<String, String>>? keyPointsRaw;

  Timestamp? createdAt;
  Timestamp? updatedAt;

  SubscriptionPackageModel({
    this.id,
    this.image,
    this.name,
    this.type,
    this.categoryType,
    this.price,
    this.discountPercentage,
    this.finalPrice,
    this.packageDuration,
    this.isUnlimited,
    this.status,
    this.isItemLimitUnlimited,
    this.itemLimit,
    this.listingDurationType,
    this.customDuration,
    this.keyPoints,
    this.keyPointsRaw,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    // Decode key points. New shape: `List<Map<code, str>>`. Legacy:
    // `List<String>` (each entry is a single localized string).
    List<Map<String, String>>? kpRaw;
    List<String>? kpLocalized;
    final rawKp = json['keyPoints'];
    if (rawKp is List) {
      kpRaw = <Map<String, String>>[];
      kpLocalized = <String>[];
      final code = ui.PlatformDispatcher.instance.locale.languageCode;
      for (final item in rawKp) {
        if (item is String) {
          if (item.isNotEmpty) {
            kpRaw.add({'default': item});
            kpLocalized.add(item);
          }
        } else if (item is Map) {
          final map = <String, String>{};
          Map<String, dynamic>.from(item).forEach((k, v) {
            if (v is String && v.isNotEmpty) map[k] = v;
          });
          if (map.isNotEmpty) {
            kpRaw.add(map);
            kpLocalized.add(_lookup(map, code));
          }
        }
      }
      if (kpRaw.isEmpty) kpRaw = null;
      if (kpLocalized.isEmpty) kpLocalized = null;
    }

    return SubscriptionPackageModel(
      id: json['id'],
      image: json['image'],
      name: json['name'] != null ? Map<String, String>.from(json['name']) : null,
      type: json['type'],
      categoryType: json['categoryType'],
      price: (json['price'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      packageDuration: json['packageDuration'],
      isUnlimited: json['isUnlimited'],
      status: json['status'],
      isItemLimitUnlimited: json['isItemLimitUnlimited'],
      itemLimit: json['itemLimit'],
      listingDurationType: json['listingDurationType'],
      customDuration: json['customDuration'],
      keyPoints: kpLocalized,
      keyPointsRaw: kpRaw,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    // Persist the raw multi-language rows when available; otherwise fall
    // back to the flat list so legacy write paths still round-trip.
    final dynamic kpOut = keyPointsRaw ?? keyPoints;
    return {
      'id': id,
      'image': image,
      'name': name,
      'type': type,
      'categoryType': categoryType,
      'price': price,
      'discountPercentage': discountPercentage,
      'finalPrice': finalPrice,
      'packageDuration': packageDuration,
      'isUnlimited': isUnlimited,
      'status': status,
      'isItemLimitUnlimited': isItemLimitUnlimited,
      'itemLimit': itemLimit,
      'listingDurationType': listingDurationType,
      'customDuration': customDuration,
      'keyPoints': kpOut,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  /// Localised package name — requested → default → en → first non-empty.
  String nameFor(String? code) => _lookup(name, code);

  /// Localised key-points list. Uses the raw rows when present so a
  /// specific language can be requested; otherwise falls back to the
  /// already-localized [keyPoints].
  List<String> keyPointsFor(String? code) {
    if (keyPointsRaw != null && keyPointsRaw!.isNotEmpty) {
      return keyPointsRaw!
          .map((row) => _lookup(row, code))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return keyPoints ?? const <String>[];
  }

  // Helper to calculate final price
  void calculateFinalPrice() {
    if (price != null && discountPercentage != null) {
      finalPrice = price! - (price! * discountPercentage! / 100);
    } else {
      finalPrice = price;
    }
  }

  static String _lookup(Map<String, String>? map, String? code) {
    if (map == null || map.isEmpty) return '';
    if (code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if ((map['default'] ?? '').isNotEmpty) return map['default']!;
    if ((map['en'] ?? '').isNotEmpty) return map['en']!;
    for (final v in map.values) {
      if (v.isNotEmpty) return v;
    }
    return '';
  }
}
