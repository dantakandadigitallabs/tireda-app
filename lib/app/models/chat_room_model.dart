import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String? id;
  String? adId;
  String? adTitle;
  String? adImage;
  double? adPrice;
  String? adCategory;
  String? adCurrencySymbol;
  bool? adCurrencySymbolAtRight;
  int? adCurrencyDecimalDigits;
  String? senderId;
  String? senderName;
  String? senderProfile;
  String? receiverId;
  String? receiverName;
  String? receiverProfile;
  String? lastMessage;
  String? lastMessageType; // 'text' | 'offer' | 'image'
  Timestamp? lastMessageTime;
  int? senderUnreadCount;
  int? receiverUnreadCount;
  Timestamp? createdAt;

  ChatRoomModel({
    this.id,
    this.adId,
    this.adTitle,
    this.adImage,
    this.adPrice,
    this.adCategory,
    this.adCurrencySymbol,
    this.adCurrencySymbolAtRight,
    this.adCurrencyDecimalDigits,
    this.senderId,
    this.senderName,
    this.senderProfile,
    this.receiverId,
    this.receiverName,
    this.receiverProfile,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.senderUnreadCount,
    this.receiverUnreadCount,
    this.createdAt,
  });

  ChatRoomModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    adId = json['adId'];
    adTitle = json['adTitle'];
    adImage = json['adImage'];
    adPrice = json['adPrice'] != null ? (json['adPrice'] as num).toDouble() : null;
    adCategory = json['adCategory'];
    adCurrencySymbol = json['adCurrencySymbol'];
    adCurrencySymbolAtRight = json['adCurrencySymbolAtRight'];
    adCurrencyDecimalDigits = json['adCurrencyDecimalDigits'];
    senderId = json['senderId'];
    senderName = json['senderName'];
    senderProfile = json['senderProfile'];
    receiverId = json['receiverId'];
    receiverName = json['receiverName'];
    receiverProfile = json['receiverProfile'];
    lastMessage = json['lastMessage'];
    lastMessageType = json['lastMessageType'];
    lastMessageTime = json['lastMessageTime'];
    senderUnreadCount = json['senderUnreadCount'] ?? 0;
    receiverUnreadCount = json['receiverUnreadCount'] ?? 0;
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adId': adId,
      'adTitle': adTitle,
      'adImage': adImage,
      'adPrice': adPrice,
      'adCategory': adCategory,
      'adCurrencySymbol': adCurrencySymbol,
      'adCurrencySymbolAtRight': adCurrencySymbolAtRight,
      'adCurrencyDecimalDigits': adCurrencyDecimalDigits,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfile': senderProfile,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverProfile': receiverProfile,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTime': lastMessageTime,
      'senderUnreadCount': senderUnreadCount ?? 0,
      'receiverUnreadCount': receiverUnreadCount ?? 0,
      'createdAt': createdAt,
    };
  }

  /// Format price with the ad's own currency
  String get formattedPrice {
    if (adPrice == null) return 'Negotiable';
    final s = adCurrencySymbol ?? '\$';
    final d = adCurrencyDecimalDigits ?? 2;
    final p = adPrice!.toStringAsFixed(d);
    return (adCurrencySymbolAtRight == true) ? '$p $s'.trim() : '$s$p'.trim();
  }

  /// Format any amount with the ad's currency
  String formatAmount(double amount) {
    final s = adCurrencySymbol ?? '\$';
    final d = adCurrencyDecimalDigits ?? 2;
    final p = amount.toStringAsFixed(d);
    return (adCurrencySymbolAtRight == true) ? '$p $s'.trim() : '$s$p'.trim();
  }

  /// Returns the other user's ID relative to the current user
  String otherUserId(String currentUserId) {
    return senderId == currentUserId ? receiverId! : senderId!;
  }

  String otherUserName(String currentUserId) {
    return senderId == currentUserId ? receiverName! : senderName!;
  }

  String otherUserProfile(String currentUserId) {
    return senderId == currentUserId ? (receiverProfile ?? '') : (senderProfile ?? '');
  }

  int myUnreadCount(String currentUserId) {
    return senderId == currentUserId ? (senderUnreadCount ?? 0) : (receiverUnreadCount ?? 0);
  }
}
