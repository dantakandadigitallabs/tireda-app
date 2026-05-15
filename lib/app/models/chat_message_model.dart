import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  String? id;
  String? chatRoomId;
  String? senderId;
  String? senderName;
  String? senderProfile;
  String? messageType; // 'text' | 'offer' | 'image' | 'video'
  String? text;
  double? offerAmount;
  String? offerStatus; // 'pending' | 'accepted' | 'rejected'
  String? imageUrl; // single image (backward compat)
  List<String>? imageUrls; // multiple images
  String? videoUrl;
  Timestamp? createdAt;
  bool? isRead;

  ChatMessageModel({
    this.id,
    this.chatRoomId,
    this.senderId,
    this.senderName,
    this.senderProfile,
    this.messageType,
    this.text,
    this.offerAmount,
    this.offerStatus,
    this.imageUrl,
    this.imageUrls,
    this.videoUrl,
    this.createdAt,
    this.isRead,
  });

  ChatMessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    chatRoomId = json['chatRoomId'];
    senderId = json['senderId'];
    senderName = json['senderName'];
    senderProfile = json['senderProfile'];
    messageType = json['messageType'] ?? 'text';
    text = json['text'];
    offerAmount = json['offerAmount'] != null ? (json['offerAmount'] as num).toDouble() : null;
    offerStatus = json['offerStatus'];
    imageUrl = json['imageUrl'];
    imageUrls = json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null;
    videoUrl = json['videoUrl'];
    createdAt = json['createdAt'];
    isRead = json['isRead'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfile': senderProfile,
      'messageType': messageType ?? 'text',
      'text': text,
      'offerAmount': offerAmount,
      'offerStatus': offerStatus,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'createdAt': createdAt,
      'isRead': isRead ?? false,
    };
  }

  /// Get all image URLs — merges imageUrls list and legacy imageUrl field
  List<String> get allImageUrls {
    final urls = <String>[];
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      urls.addAll(imageUrls!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      urls.add(imageUrl!);
    }
    return urls;
  }
}
