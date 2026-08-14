// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/models/currency_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/models/positions_model.dart';
import 'package:intl/intl.dart';

class AdModel {
  String? id;

  /// Default-language title. See [titleFor] for a localised read.
  String? title;

  /// Per-language title map (e.g. `{ default: "...", ar: "..." }`).
  /// Null on legacy documents where `title` was written as a flat String.
  // Tireda Custom Merge (eSellify 1.5): dynamic localization support.
  Map<String, String>? titleTranslations;

  /// Default-language description.
  String? description;

  /// Per-language description map.
  // Tireda Custom Merge (eSellify 1.5): dynamic localization support.
  Map<String, String>? descriptionTranslations;

  String? slug;
  double? price;
  bool? isPriceOptional;
  // Tireda Custom: "Price Negotiable" flag for normal fixed-price ads.
  // Only meaningful when isJobCategory != true and isPriceOptional != true —
  // AddProductsController force-sets this false at save time for those
  // categories, but it's still nullable/defaulted here defensively.
  bool? isNegotiable;
  // ─── Job category fields ─────────────────────────────────
  // For ads posted under a Job Category, price is replaced by a salary range.
  bool? isJobCategory;
  double? minSalary;
  double? maxSalary;
  CurrencyModel? currency;
  List<String>? categoryPath;
  List<String>? categoryNamePath;
  String? get leafCategoryId =>
      (categoryPath?.isNotEmpty ?? false) ? categoryPath!.last : null;
  String? get leafCategoryName =>
      (categoryNamePath?.isNotEmpty ?? false) ? categoryNamePath!.last : null;
  String? get parentCategoryId =>
      (categoryPath != null && categoryPath!.length >= 2)
          ? categoryPath![categoryPath!.length - 2]
          : null;

  /// True when this ad belongs to a Job Category, in which case it carries a
  /// salary range (minSalary / maxSalary) instead of a price.
  bool get isJobAd =>
      isJobCategory == true || minSalary != null || maxSalary != null;

  /// Formats the salary range using the ad's currency, e.g. "$1,000 – $2,000".
  // Tireda Custom: uses NumberFormat for thousands separators.
  // eSellify 1.5 base reverted this to plain toStringAsFixed — intentionally
  // NOT taken, this version is preserved as-is.
  String formattedSalary() {
    final c = currency;
    final s = c?.symbol ?? '';
    final d = c?.decimalDigits ?? 0;
    final atRight = c?.symbolAtRight == true;

    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: d,
    );

    String fmt(double v) {
      final p = formatter.format(v).trim();
      return atRight ? "$p $s".trim() : "$s$p".trim();
    }

    if (minSalary != null && maxSalary != null) {
      return "${fmt(minSalary!)} – ${fmt(maxSalary!)}";
    }
    if (minSalary != null) return "From ${fmt(minSalary!)}";
    if (maxSalary != null) return "Up to ${fmt(maxSalary!)}";
    return "Negotiable";
  }

  String? sellerId;
  String? sellerName;
  String? sellerProfile;
  // Tireda Custom: not present in eSellify 1.5 base.
  bool? isSellerVerified;
  String? countryCode;
  String? phoneNumber;
  String? address;
  LocationLatLng? location;
  Positions? position;
  String? mainImage;
  List<String>? otherImages;
  List<Map<String, dynamic>>? customFields;
  int? views;
  int? likes;
  List<dynamic>? likedUser;
  String? status;
  bool? isActive;
  bool? isFeatured;
  Timestamp? featuredUntil;
  String? rejectionReason;
  String? soldToUserId;
  String? soldToUserName;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  Timestamp? expiryDate;
  List<String>? searchKeywords;

  AdModel({
    this.id,
    this.title,
    this.titleTranslations,
    this.description,
    this.descriptionTranslations,
    this.slug,
    this.price,
    this.isPriceOptional,
    this.isNegotiable,
    this.isJobCategory,
    this.minSalary,
    this.maxSalary,
    this.currency,
    this.categoryPath,
    this.categoryNamePath,
    this.sellerId,
    this.sellerName,
    this.sellerProfile,
    this.isSellerVerified,
    this.countryCode,
    this.phoneNumber,
    this.address,
    this.location,
    this.position,
    this.mainImage,
    this.otherImages,
    this.customFields,
    this.views,
    this.likes,
    this.likedUser,
    this.status,
    this.isActive,
    this.isFeatured,
    this.featuredUntil,
    this.rejectionReason,
    this.soldToUserId,
    this.soldToUserName,
    this.createdAt,
    this.updatedAt,
    this.expiryDate,
    this.searchKeywords,
  });

  /// Reads a Firestore document. `title` and `description` are normalised
  /// against both shapes — legacy flat String and new-format Map<code, String>
  /// (as written by the admin panel's Localization Tab). Downstream reads
  /// of the flat [title] / [description] still work; localised reads should
  /// use [titleFor] / [descriptionFor].
  AdModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    final rawTitle = json['title'];
    if (rawTitle is Map) {
      titleTranslations = _coerceToStringMap(Map<String, dynamic>.from(rawTitle));
      title = _extractDefault(titleTranslations!);
    } else {
      title = rawTitle is String ? rawTitle : null;
      titleTranslations = null;
    }
    final rawDesc = json['description'];
    if (rawDesc is Map) {
      descriptionTranslations = _coerceToStringMap(Map<String, dynamic>.from(rawDesc));
      description = _extractDefault(descriptionTranslations!);
    } else {
      description = rawDesc is String ? rawDesc : null;
      descriptionTranslations = null;
    }
    slug = json['slug'];
    price = json['price'] != null ? (json['price'] as num).toDouble() : null;
    isPriceOptional = json['isPriceOptional'];
    isNegotiable = json['isNegotiable'] ?? false;
    isJobCategory = json['isJobCategory'] ?? false;
    minSalary =
    json['minSalary'] != null ? (json['minSalary'] as num).toDouble() : null;
    maxSalary =
    json['maxSalary'] != null ? (json['maxSalary'] as num).toDouble() : null;
    currency = json['currency'] != null
        ? CurrencyModel.fromJson(json['currency'])
        : null;
    categoryPath = json['categoryPath'] != null
        ? List<String>.from(json['categoryPath'])
        : [];
    categoryNamePath = json['categoryNamePath'] != null
        ? List<String>.from(json['categoryNamePath'])
        : [];
    sellerId = json['sellerId'];
    sellerName = json['sellerName'];
    sellerProfile = json['sellerProfile'];
    isSellerVerified = json['isSellerVerified'] ?? false;
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'];
    address = json['address'];
    location = json['location'] != null
        ? LocationLatLng.fromJson(json['location'])
        : null;
    position = json['position'] != null
        ? Positions.fromJson(json['position'])
        : null;
    mainImage = json['mainImage'];
    otherImages = json['otherImages'] != null
        ? List<String>.from(json['otherImages'])
        : [];
    customFields = json['customFields'] != null
        ? List<Map<String, dynamic>>.from(
        (json['customFields'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
        : [];
    views = json['views'] != null ? (json['views'] as num).toInt() : 0;
    likes = json['likes'] != null ? (json['likes'] as num).toInt() : 0;
    likedUser = json['likedUser'] ?? [];
    status = json['status'];
    isActive = json['isActive'];
    isFeatured = json['isFeatured'] ?? false;
    featuredUntil = json['featuredUntil'];
    rejectionReason = json['rejectionReason'];
    soldToUserId = json['soldToUserId'];
    soldToUserName = json['soldToUserName'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    expiryDate = json['expiryDate'];
    searchKeywords = json['searchKeywords'] != null
        ? List<String>.from(json['searchKeywords'])
        : [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': (titleTranslations != null && titleTranslations!.isNotEmpty)
          ? titleTranslations
          : title,
      'description': (descriptionTranslations != null && descriptionTranslations!.isNotEmpty)
          ? descriptionTranslations
          : description,
      'slug': slug,
      'price': price,
      'isPriceOptional': isPriceOptional,
      'isNegotiable': isNegotiable ?? false,
      'isJobCategory': isJobCategory ?? false,
      'minSalary': minSalary,
      'maxSalary': maxSalary,
      'currency': currency?.toJson(),
      'categoryPath': categoryPath ?? [],
      'categoryNamePath': categoryNamePath ?? [],
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerProfile': sellerProfile,
      'isSellerVerified': isSellerVerified ?? false,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'address': address,
      'location': location?.toJson(),
      'position': position?.toJson(),
      'mainImage': mainImage,
      'otherImages': otherImages ?? [],
      'customFields': customFields ?? [],
      'views': views ?? 0,
      'likes': likes ?? 0,
      'likedUser': likedUser ?? [],
      'status': status,
      'isActive': isActive,
      'isFeatured': isFeatured ?? false,
      'featuredUntil': featuredUntil,
      'rejectionReason': rejectionReason,
      'soldToUserId': soldToUserId,
      'soldToUserName': soldToUserName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'expiryDate': expiryDate,
      'searchKeywords': searchKeywords ?? [],
    };
  }

  /// Returns the localised title for [code] with graceful fallback:
  /// requested → `default` → `en` → the flat [title].
  String titleFor(String? code) => _lookup(titleTranslations, code, title);

  /// Returns the localised description for [code]. Same fallback rules as
  /// [titleFor].
  String descriptionFor(String? code) => _lookup(descriptionTranslations, code, description);

  static String _lookup(Map<String, String>? map, String? code, String? fallback) {
    if (map != null && code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
    if (map != null && (map['default'] ?? '').isNotEmpty) return map['default']!;
    if (map != null && (map['en'] ?? '').isNotEmpty) return map['en']!;
    return fallback ?? '';
  }

  static Map<String, String> _coerceToStringMap(Map<String, dynamic> raw) {
    final Map<String, String> out = {};
    raw.forEach((code, value) {
      if (value is String) {
        out[code] = value;
      } else if (value is Map && value['name'] is String) {
        out[code] = value['name'] as String;
      }
    });
    return out;
  }

  static String _extractDefault(Map<String, String> map) {
    if ((map['default'] ?? '').isNotEmpty) return map['default']!;
    if ((map['en'] ?? '').isNotEmpty) return map['en']!;
    for (final v in map.values) {
      if (v.isNotEmpty) return v;
    }
    return '';
  }
}