import 'package:cloud_firestore/cloud_firestore.dart';

class AdReportModel {
  String? id;
  String? adId;
  String? adTitle;
  String? adImage;
  String? reporterId;
  String? reporterName;
  String? reporterEmail;
  String? sellerId;
  String? sellerName;
  String? reasonId;

  /// Flat default-language reason title — kept for the admin panel and
  /// legacy readers. Display code in the customer apps should prefer
  /// [reasonTitleFor] so mid-session language changes take effect.
  String? reasonTitle;

  /// Per-language snapshot of the report reason's title at the moment
  /// the report was filed. Persisted so the report card stays localized
  /// even if the reason doc is later edited or deleted.
  Map<String, String>? reasonTitleTranslations;

  String? description;
  String? status;
  String? adminNotes;
  Timestamp? createdAt;
  Timestamp? reviewedAt;

  AdReportModel({
    this.id, this.adId, this.adTitle, this.adImage,
    this.reporterId, this.reporterName, this.reporterEmail,
    this.sellerId, this.sellerName,
    this.reasonId, this.reasonTitle, this.reasonTitleTranslations,
    this.description,
    this.status, this.adminNotes, this.createdAt, this.reviewedAt,
  });

  AdReportModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    adId = json['adId'];
    adTitle = json['adTitle'];
    adImage = json['adImage'];
    reporterId = json['reporterId'];
    reporterName = json['reporterName'];
    reporterEmail = json['reporterEmail'];
    sellerId = json['sellerId'];
    sellerName = json['sellerName'];
    reasonId = json['reasonId'];
    // Accept both new and legacy shapes:
    //   • `reasonTitle` as a flat String (older reports)
    //   • `reasonTitle` as a Map — some early docs stored the map here
    //   • `reasonTitleTranslations` as a Map (new — preferred)
    final rawTitle = json['reasonTitle'];
    if (rawTitle is Map) {
      reasonTitleTranslations = <String, String>{};
      Map<String, dynamic>.from(rawTitle).forEach((k, v) {
        if (v is String) reasonTitleTranslations![k] = v;
      });
      reasonTitle = (reasonTitleTranslations!['default'] ?? '').isNotEmpty
          ? reasonTitleTranslations!['default']
          : (reasonTitleTranslations!['en'] ?? '');
    } else {
      reasonTitle = rawTitle is String ? rawTitle : null;
    }
    final rawTitleTx = json['reasonTitleTranslations'];
    if (rawTitleTx is Map) {
      reasonTitleTranslations = <String, String>{};
      Map<String, dynamic>.from(rawTitleTx).forEach((k, v) {
        if (v is String) reasonTitleTranslations![k] = v;
      });
    }
    description = json['description'];
    status = json['status'] ?? 'pending';
    adminNotes = json['adminNotes'];
    createdAt = json['createdAt'];
    reviewedAt = json['reviewedAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adId': adId,
      'adTitle': adTitle,
      'adImage': adImage,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'reasonId': reasonId,
      'reasonTitle': reasonTitle,
      'reasonTitleTranslations': reasonTitleTranslations,
      'description': description,
      'status': status ?? 'pending',
      'adminNotes': adminNotes,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
    };
  }

  /// Localised reason title — `map[code] → default → en → flat`.
  String reasonTitleFor(String? code) {
    final m = reasonTitleTranslations;
    if (m != null && code != null && (m[code] ?? '').isNotEmpty) return m[code]!;
    if (m != null && (m['default'] ?? '').isNotEmpty) return m['default']!;
    if (m != null && (m['en'] ?? '').isNotEmpty) return m['en']!;
    return reasonTitle ?? '';
  }
}
