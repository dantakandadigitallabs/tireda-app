import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPackageModel {
  String? id;
  String? image;
  Map<String, String>? name;
  String? type;
  String? categoryType;
  // List<String>? selectedCategories;
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
  List<String>? keyPoints;
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
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
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
      keyPoints: json['keyPoints'] != null ? List<String>.from(json['keyPoints']) : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
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
      'keyPoints': keyPoints,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // Helper to calculate final price
  void calculateFinalPrice() {
    if (price != null && discountPercentage != null) {
      finalPrice = price! - (price! * discountPercentage! / 100);
    } else {
      finalPrice = price;
    }
  }
}
