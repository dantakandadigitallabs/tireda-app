// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/models/currency_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/models/positions_model.dart';

class AdModel {
  String? id;
  String? title;
  String? description;
  String? slug;
  double? price;
  bool? isPriceOptional;
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
  String? sellerId;
  String? sellerName;
  String? sellerProfile;
  bool? isSellerVerified; // Added Verified Flag
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
    this.description,
    this.slug,
    this.price,
    this.isPriceOptional,
    this.currency,
    this.categoryPath,
    this.categoryNamePath,
    this.sellerId,
    this.sellerName,
    this.sellerProfile,
    this.isSellerVerified, // Added to constructor
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

  AdModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    slug = json['slug'];
    price = json['price'] != null ? (json['price'] as num).toDouble() : null;
    isPriceOptional = json['isPriceOptional'];
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
    isSellerVerified = json['isSellerVerified'] ?? false; // Maps from JSON
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
      'title': title,
      'description': description,
      'slug': slug,
      'price': price,
      'isPriceOptional': isPriceOptional,
      'currency': currency?.toJson(),
      'categoryPath': categoryPath ?? [],
      'categoryNamePath': categoryNamePath ?? [],
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerProfile': sellerProfile,
      'isSellerVerified': isSellerVerified ?? false, // Maps to JSON
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
}