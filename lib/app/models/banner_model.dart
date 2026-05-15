import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  String? id;
  String? title;
  String? image;
  String? redirectType;
  String? redirectValue;
  String? redirectLabel;
  bool? active;
  int? sortOrder;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  BannerModel({
    this.id,
    this.title,
    this.image,
    this.redirectType,
    this.redirectValue,
    this.redirectLabel,
    this.active,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  BannerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    image = json['image'];
    redirectType = json['redirectType'];
    redirectValue = json['redirectValue'];
    redirectLabel = json['redirectLabel'];
    active = json['active'] ?? false;
    sortOrder = json['sortOrder'] ?? 0;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'redirectType': redirectType,
      'redirectValue': redirectValue,
      'redirectLabel': redirectLabel,
      'active': active ?? false,
      'sortOrder': sortOrder ?? 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
