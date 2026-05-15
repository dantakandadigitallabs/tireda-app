import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationDocumentModel {
  String? id;
  String? name;
  String? description;
  String? type; // 'file', 'image', 'textfield'
  String? imageSides; // 'one', 'two' (only for type == 'image')
  bool? isRequired;
  bool? active;
  int? order;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  VerificationDocumentModel({
    this.id,
    this.name,
    this.description,
    this.type,
    this.imageSides,
    this.isRequired,
    this.active,
    this.order,
    this.createdAt,
    this.updatedAt,
  });

  VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    type = json['type'];
    imageSides = json['imageSides'];
    isRequired = json['isRequired'];
    active = json['active'];
    order = json['order'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'imageSides': imageSides,
      'isRequired': isRequired,
      'active': active,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
