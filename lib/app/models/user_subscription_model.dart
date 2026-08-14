import 'package:cloud_firestore/cloud_firestore.dart';

class UserSubscriptionModel {
  String? id;
  String? userId;
  String? packageId;

  /// Default-language snapshot of the package name at purchase time.
  /// Display code should prefer [packageNameFor] so mid-session
  /// language switches take effect immediately.
  String? packageName;

  /// Per-language snapshot of the package name — mirrors the shape of
  /// `subscription_packages.name` in Firestore.
  Map<String, String>? packageNameTranslations;

  String? packageImage;
  String? packageType; // 'ad_listing' | 'featured_ads'
  double? price;
  String? status; // 'active' | 'expired' | 'cancelled' | 'merged' (Tireda)
  Timestamp? purchaseDate;
  Timestamp? expiryDate; // null = unlimited
  int? adsPosted;
  int? adLimit;
  bool? isItemLimitUnlimited;
  String? listingDurationType; // 'standard' | 'package' | 'custom'
  int? customDuration;
  int? packageDuration;
  String? paymentId; // links to TransactionModel
  String? paymentMethod;

  UserSubscriptionModel({
    this.id,
    this.userId,
    this.packageId,
    this.packageName,
    this.packageNameTranslations,
    this.packageImage,
    this.packageType,
    this.price,
    this.status,
    this.purchaseDate,
    this.expiryDate,
    this.adsPosted,
    this.adLimit,
    this.isItemLimitUnlimited,
    this.listingDurationType,
    this.customDuration,
    this.packageDuration,
    this.paymentId,
    this.paymentMethod,
  });

  /// Check if subscription is currently active
  bool get isActive {
    if (status != 'active') return false;
    if (expiryDate == null) return true; // unlimited
    return expiryDate!.toDate().isAfter(DateTime.now());
  }

  /// Check if user can still post ads
  bool get canPostAd {
    if (!isActive) return false;
    if (isItemLimitUnlimited == true) return true;
    return (adsPosted ?? 0) < (adLimit ?? 0);
  }

  /// Remaining ads count
  int get remainingAds {
    if (isItemLimitUnlimited == true) return -1; // unlimited
    return (adLimit ?? 0) - (adsPosted ?? 0);
  }

  /// Days remaining
  int get daysRemaining {
    if (expiryDate == null) return -1; // unlimited
    final remaining = expiryDate!.toDate().difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    packageId = json['packageId'];
    // Accept both flat String (legacy) and Map<code, String> (new).
    //
    // Tireda fix: removed a second block that re-parsed a top-level
    // 'packageNameTranslations' key and unconditionally overwrote the
    // map derived below. toJson() never writes that key on its own —
    // Tireda always writes translations nested under 'packageName' —
    // so that block was dead code against our own data and unsafe
    // against any hypothetical external write (see same fix applied
    // to TransactionModel).
    final rawName = json['packageName'];
    if (rawName is Map) {
      packageNameTranslations = <String, String>{};
      Map<String, dynamic>.from(rawName).forEach((k, v) {
        if (v is String) packageNameTranslations![k] = v;
      });
      packageName = (packageNameTranslations!['default'] ?? '').isNotEmpty
          ? packageNameTranslations!['default']
          : (packageNameTranslations!['en'] ?? '');
    } else {
      packageName = rawName is String ? rawName : null;
    }
    packageImage = json['packageImage'];
    packageType = json['packageType'];
    price = json['price'] != null ? (json['price'] as num).toDouble() : null;
    status = json['status'] ?? 'active';
    purchaseDate = json['purchaseDate'];
    expiryDate = json['expiryDate'];
    adsPosted = json['adsPosted'] ?? 0;
    adLimit = json['adLimit'] ?? 0;
    isItemLimitUnlimited = json['isItemLimitUnlimited'] ?? false;
    listingDurationType = json['listingDurationType'];
    customDuration = json['customDuration'];
    packageDuration = json['packageDuration'];
    paymentId = json['paymentId'];
    paymentMethod = json['paymentMethod'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'packageId': packageId,
      // Persist the full multi-language map when we have one, so the
      // Firestore shape matches subscription_packages.name.
      'packageName': (packageNameTranslations != null && packageNameTranslations!.isNotEmpty)
          ? packageNameTranslations
          : packageName,
      'packageImage': packageImage,
      'packageType': packageType,
      'price': price,
      'status': status ?? 'active',
      'purchaseDate': purchaseDate,
      'expiryDate': expiryDate,
      'adsPosted': adsPosted ?? 0,
      'adLimit': adLimit ?? 0,
      'isItemLimitUnlimited': isItemLimitUnlimited ?? false,
      'listingDurationType': listingDurationType,
      'customDuration': customDuration,
      'packageDuration': packageDuration,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
    };
  }

  /// Localised package name — `map[code] → default → en → flat`.
  String packageNameFor(String? code) {
    final m = packageNameTranslations;
    if (m != null && code != null && (m[code] ?? '').isNotEmpty) return m[code]!;
    if (m != null && (m['default'] ?? '').isNotEmpty) return m['default']!;
    if (m != null && (m['en'] ?? '').isNotEmpty) return m['en']!;
    return packageName ?? '';
  }
}