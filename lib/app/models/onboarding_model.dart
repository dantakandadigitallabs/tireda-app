// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';

class OnBoardingModel {
  String? id;
  String? title;
  String? description;
  String? type;
  String? image;
  bool? status;
  Timestamp? createdAt;

  OnBoardingModel({this.id, this.title, this.description, this.type, this.image, this.status, this.createdAt});

  OnBoardingModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    type = json['type'];
    image = json['image'];
    status = json['status'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['type'] = type;
    data['image'] = image;
    data['status'] = status;
    data['createdAt'] = createdAt;
    return data;
  }
}
