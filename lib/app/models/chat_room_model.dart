import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String? id;
  String? adId;
  String? adTitle;
  String? adImage;
  double? adPrice;
  // Job category fields — when set, the ad is a job posting (salary instead of price).
  bool? isJobCategory;
  double? minSalary;
  double? maxSalary;
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
    this.isJobCategory,
    this.minSalary,
    this.maxSalary,
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
    isJobCategory = json['isJobCategory'] ?? false;
    minSalary = json['minSalary'] != null ? (json['minSalary'] as num).toDouble() : null;
    maxSalary = json['maxSalary'] != null ? (json['maxSalary'] as num).toDouble() : null;
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
      'isJobCategory': isJobCategory ?? false,
      'minSalary': minSalary,
      'maxSalary': maxSalary,
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

  /// True when this chat is about a job posting.
  bool get isJobAd => isJobCategory == true || minSalary != null || maxSalary != null;

  /// Format price with the ad's own currency
  String get formattedPrice {
    if (adPrice == null) return 'Negotiable';
    final s = adCurrencySymbol ?? '\$';
    final d = adCurrencyDecimalDigits ?? 2;
    final p = adPrice!.toStringAsFixed(d);
    return (adCurrencySymbolAtRight == true) ? '$p $s'.trim() : '$s$p'.trim();
  }

  /// Salary range for job ads (uses the ad's currency).
  String get formattedSalary {
    final s = adCurrencySymbol ?? '\$';
    final d = adCurrencyDecimalDigits ?? 0;
    final atRight = adCurrencySymbolAtRight == true;
    String fmt(double v) {
      final p = v.toStringAsFixed(d);
      return atRight ? '$p $s'.trim() : '$s$p'.trim();
    }

    if (minSalary != null && maxSalary != null) return '${fmt(minSalary!)} – ${fmt(maxSalary!)}';
    if (minSalary != null) return 'From ${fmt(minSalary!)}';
    if (maxSalary != null) return 'Up to ${fmt(maxSalary!)}';
    return 'Negotiable';
  }

  /// Price for normal ads, salary range for job ads — for header display.
  String get priceOrSalaryLabel => isJobAd ? formattedSalary : formattedPrice;

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
