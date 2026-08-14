import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String? userId;
  String? userName;
  String? userEmail;
  String? packageId;

  /// Default-language snapshot of the subscription package name at the
  /// time of purchase. Display code should prefer [packageNameFor] so
  /// switching app language later still shows the correct language.
  String? packageName;

  /// Per-language snapshot of the package name (`{ default, en, ar, hi, … }`).
  /// Persisted so payment history stays localized even if the source
  /// package doc is later edited or deleted.
  Map<String, String>? packageNameTranslations;

  String? packageType; // 'ad_listing' | 'featured_ads'
  double? amount;
  String? currency;
  String? paymentMethod; // 'wallet' | 'stripe' | 'razorpay' | 'paypal' etc.
  String? paymentStatus; // 'success' | 'failed' | 'pending'
  String? transactionId; // gateway reference ID
  String? subscriptionId; // links to UserSubscriptionModel
  Timestamp? createdAt;

  TransactionModel({
    this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.packageId,
    this.packageName,
    this.packageNameTranslations,
    this.packageType,
    this.amount,
    this.currency,
    this.paymentMethod,
    this.paymentStatus,
    this.transactionId,
    this.subscriptionId,
    this.createdAt,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    userName = json['userName'];
    userEmail = json['userEmail'];
    packageId = json['packageId'];
    // Accept both flat String (legacy docs) and Map<code, String>
    // (new multi-language snapshot). Populate both fields so any
    // downstream reader — old or new — sees a sensible value.
    //
    // Tireda fix: removed a second block that re-parsed a top-level
    // 'packageNameTranslations' key and unconditionally overwrote the
    // map derived above. toJson() never writes that key on its own —
    // Tireda always writes translations nested under 'packageName' —
    // so that block was both dead code against our own data and unsafe
    // against any hypothetical external write (it discarded the valid
    // translations parsed from 'packageName' above instead of merging).
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
    packageType = json['packageType'];
    amount = json['amount'] != null ? (json['amount'] as num).toDouble() : null;
    currency = json['currency'];
    paymentMethod = json['paymentMethod'];
    paymentStatus = json['paymentStatus'] ?? 'pending';
    transactionId = json['transactionId'];
    subscriptionId = json['subscriptionId'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'packageId': packageId,
      // Persist the full multi-language map when we have one so the
      // Firestore shape matches subscription_packages.name; fall back
      // to the flat String only when no translations are available.
      'packageName': (packageNameTranslations != null && packageNameTranslations!.isNotEmpty)
          ? packageNameTranslations
          : packageName,
      'packageType': packageType,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus ?? 'pending',
      'transactionId': transactionId,
      'subscriptionId': subscriptionId,
      'createdAt': createdAt,
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