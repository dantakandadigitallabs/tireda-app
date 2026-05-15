import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String? userId;
  String? userName;
  String? userEmail;
  String? packageId;
  String? packageName;
  String? packageType; // 'ad_listing' | 'featured_ads'
  double? amount;
  String? currency;
  String? paymentMethod; // 'wallet' | 'stripe' | 'razorpay' | 'paypal' etc.
  String? paymentStatus; // 'success' | 'failed' | 'pending'
  String? transactionId; // gateway reference ID
  String? subscriptionId; // links to UserSubscriptionModel
  Timestamp? createdAt;

  TransactionModel({
    this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.packageId,
    this.packageName,
    this.packageType,
    this.amount,
    this.currency,
    this.paymentMethod,
    this.paymentStatus,
    this.transactionId,
    this.subscriptionId,
    this.createdAt,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    userName = json['userName'];
    userEmail = json['userEmail'];
    packageId = json['packageId'];
    packageName = json['packageName'];
    packageType = json['packageType'];
    amount = json['amount'] != null ? (json['amount'] as num).toDouble() : null;
    currency = json['currency'];
    paymentMethod = json['paymentMethod'];
    paymentStatus = json['paymentStatus'] ?? 'pending';
    transactionId = json['transactionId'];
    subscriptionId = json['subscriptionId'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'packageId': packageId,
      'packageName': packageName,
      'packageType': packageType,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus ?? 'pending',
      'transactionId': transactionId,
      'subscriptionId': subscriptionId,
      'createdAt': createdAt,
    };
  }
}
