import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  String? id;
  String? sellerId;
  String? sellerName;
  String? buyerId;
  String? buyerName;
  String? buyerProfile;
  String? adId; // which ad triggered this review
  String? adTitle;
  String? adImage;
  double? rating; // 1.0 - 5.0
  String? comment;
  Timestamp? createdAt;

  ReviewModel({
    this.id,
    this.sellerId,
    this.sellerName,
    this.buyerId,
    this.buyerName,
    this.buyerProfile,
    this.adId,
    this.adTitle,
    this.adImage,
    this.rating,
    this.comment,
    this.createdAt,
  });

  ReviewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sellerId = json['sellerId'];
    sellerName = json['sellerName'];
    buyerId = json['buyerId'];
    buyerName = json['buyerName'];
    buyerProfile = json['buyerProfile'];
    adId = json['adId'];
    adTitle = json['adTitle'];
    adImage = json['adImage'];
    rating = json['rating'] != null ? (json['rating'] as num).toDouble() : null;
    comment = json['comment'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerProfile': buyerProfile,
      'adId': adId,
      'adTitle': adTitle,
      'adImage': adImage,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
