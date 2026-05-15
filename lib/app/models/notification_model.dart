// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? id;
  String? type;
  String? userType;
  String? title;
  String? description;
  String? adId;
  String? chatRoomId;
  String? receiverId;
  String? senderId;
  bool? isRead;
  Timestamp? createdAt;

  NotificationModel({this.id, this.type, this.userType, this.title, this.description, this.adId, this.chatRoomId, this.receiverId, this.senderId, this.isRead, this.createdAt});

  NotificationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    userType = json['userType'];
    title = json['title'];
    description = json['description'];
    adId = json['adId'];
    chatRoomId = json['chatRoomId'];
    receiverId = json['receiverId'];
    senderId = json['senderId'];
    isRead = json['isRead'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['userType'] = userType;
    data['title'] = title;
    data['description'] = description;
    data['adId'] = adId;
    data['chatRoomId'] = chatRoomId;
    data['receiverId'] = receiverId;
    data['senderId'] = senderId;
    data['isRead'] = isRead;
    data['createdAt'] = createdAt;
    return data;
  }

  Map<String, dynamic> toNotificationJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['userType'] = userType;
    data['title'] = title;
    data['description'] = description;
    data['adId'] = adId;
    data['chatRoomId'] = chatRoomId;
    data['receiverId'] = receiverId;
    data['senderId'] = senderId;
    data['isRead'] = isRead;
    return data;
  }
}
