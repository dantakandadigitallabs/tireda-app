import 'package:cloud_firestore/cloud_firestore.dart';

class ReportReasonModel {
  String? id;
  String? title;
  String? description;
  bool? active;
  int? sortOrder;
  Timestamp? createdAt;

  ReportReasonModel({this.id, this.title, this.description, this.active, this.sortOrder, this.createdAt});

  ReportReasonModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    active = json['active'] ?? true;
    sortOrder = json['sortOrder'] ?? 0;
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'active': active ?? true,
      'sortOrder': sortOrder ?? 0,
      'createdAt': createdAt,
    };
  }
}
