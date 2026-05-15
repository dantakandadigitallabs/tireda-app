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
  String? reasonTitle;
  String? description;
  String? status;
  String? adminNotes;
  Timestamp? createdAt;
  Timestamp? reviewedAt;

  AdReportModel({
    this.id, this.adId, this.adTitle, this.adImage,
    this.reporterId, this.reporterName, this.reporterEmail,
    this.sellerId, this.sellerName,
    this.reasonId, this.reasonTitle, this.description,
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
    reasonTitle = json['reasonTitle'];
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
      'description': description,
      'status': status ?? 'pending',
      'adminNotes': adminNotes,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
    };
  }
}
