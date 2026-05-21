import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/app/models/chat_message_model.dart';
import 'package:eSellify/app/modules/chats/views/chat_detail_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:eSellify/app/constant/show_toast.dart';

class AdListingDetailController extends GetxController {
  late AdModel ad;
  RxBool isLiked = false.obs;
  RxInt likeCount = 0.obs;
  RxInt viewCount = 0.obs;

  // Report state
  RxBool hasReported = false.obs;
  Rx<AdReportModel?> existingReport = Rx<AdReportModel?>(null);

  // Seller verification + rating
  RxBool isSellerVerified = false.obs;
  RxDouble sellerRating = 0.0.obs;
  RxInt sellerReviewCount = 0.obs;

  @override
  void onInit() {
  super.onInit();
  final args = Get.arguments;
  if (args != null && args['ad'] != null) {
  ad = args['ad'] as AdModel;
  likeCount.value = ad.likes ?? 0;
  viewCount.value = ad.views ?? 0;
  _checkLiked();
  _incrementViews();
  _checkReportStatus();
  _checkSellerVerification();
  }
  }

  Future<void> _checkSellerVerification() async {
  if (ad.sellerId == null) return;
  final seller = await FireStoreUtils.getUserProfile(ad.sellerId!);
  if (seller != null && seller.isVerified == true && seller.verificationStatus == "approved") {
  isSellerVerified.value = true;
  }
  // Fetch seller rating
  final ratingData = await FireStoreUtils.getSellerRating(ad.sellerId!);
  sellerRating.value = ratingData['average'] as double;
  sellerReviewCount.value = ratingData['count'] as int;
  }

  Future<void> _checkReportStatus() async {
  final uid = FireStoreUtils.getCurrentUid();
  if (uid == null || ad.id == null) return;
  final reports = await FireStoreUtils.getMyReports(uid);
  final match = reports.where((r) => r.adId == ad.id).toList();
  if (match.isNotEmpty) {
  hasReported.value = true;
  existingReport.value = match.first;
  }
  }

  void onReportSubmitted(AdReportModel report) {
  hasReported.value = true;
  existingReport.value = report;
  }

  void _checkLiked() {
  final uid = FireStoreUtils.getCurrentUid();
  if (uid != null) {
  isLiked.value = FireStoreUtils.isAdLikedByUser(ad, uid);
  }
  }

  Future<void> _incrementViews() async {
  if (ad.id != null) {
  await FireStoreUtils.incrementAdViews(ad.id!);
  // Fetch accurate count from subcollection
  final count = await FireStoreUtils.getAdViewerCount(ad.id!);
  viewCount.value = count;
  }
  }

  Future<void> toggleLike() async {
  final uid = FireStoreUtils.getCurrentUid();
  if (uid == null) return;

  final liked = await FireStoreUtils.toggleLike(ad.id!, uid);
  isLiked.value = liked;
  likeCount.value += liked ? 1 : -1;

  if (liked) {
  ad.likedUser ??= [];
  ad.likedUser!.add(uid);
  } else {
  ad.likedUser?.remove(uid);
  }
  ad.likes = likeCount.value;
  }

  void shareAd() {
  if (ad.id == null || ad.id!.isEmpty) {
  ShowToastDialog.showError("Unable to share this ad");
  return;
  }
  final appName = Constant.appName.value;
  final android = Constant.androidAppUrl.value.trim();
  final ios = Constant.iosAppUrl.value.trim();
  final lines = <String>[
  if ((ad.title ?? '').isNotEmpty) ad.title!,
  _formatPrice(),
  '',
  'Check it out on $appName:',
  if (android.isNotEmpty) 'Android: $android',
  if (ios.isNotEmpty) 'iOS: $ios',
  ];
  Clipboard.setData(ClipboardData(text: lines.join('\n')));
  ShowToastDialog.showSuccess("Ad link copied to clipboard!");
  }

  String _formatPrice() {
  if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
  final c = ad.currency;
  final s = c?.symbol ?? '';
  final d = c?.decimalDigits ?? 0;
  final p = ad.price!.toStringAsFixed(d);
  return c?.symbolAtRight == true ? "$p $s".trim() : "$s$p".trim();
  }

  // ─── Chat Methods ─────────────────────────────────────────

  Future<void> openChat() async {
  if (FireStoreUtils.getCurrentUid() == null) {
  ShowToastDialog.showError("Please login to chat with the seller");
  return;
  }
  if (ad.sellerId == FireStoreUtils.getCurrentUid()) {
  ShowToastDialog.showWarning("This is your own ad");
  return;
  }

  // Check if ad is sold out
  if (ad.status == 'sold') {
  ShowToastDialog.showError("This ad has been sold out");
  return;
  }

  // Check if ad is still active
  if (ad.status != 'active' || ad.isActive != true) {
  ShowToastDialog.showError("This ad is no longer active");
  return;
  }

  // Check if seller is blocked
  final blockedUsers = await FireStoreUtils.getBlockedUsers(FireStoreUtils.getCurrentUid()!);
  if (blockedUsers.contains(ad.sellerId)) {
  ShowToastDialog.showError("You have blocked this user. Unblock them to start a chat.");
  return;
  }

  ShowToastDialog.showLoader("Opening chat...");
  final chatRoom = await FireStoreUtils.getOrCreateChatRoom(ad: ad, currentUser: Constant.userModel!);
  ShowToastDialog.closeLoader();

  Get.to(() => ChatDetailView(chatRoom: chatRoom));
  }

  Future<void> sendOffer(double amount) async {
  if (FireStoreUtils.getCurrentUid() == null) {
  ShowToastDialog.showError("Please login to make an offer");
  return;
  }
  if (ad.sellerId == FireStoreUtils.getCurrentUid()) {
  ShowToastDialog.showWarning("This is your own ad");
  return;
  }

  // Check if ad is sold out
  if (ad.status == 'sold') {
  ShowToastDialog.showError("This ad has been sold out");
  return;
  }

  // Check if ad is still active
  if (ad.status != 'active' || ad.isActive != true) {
  ShowToastDialog.showError("This ad is no longer active");
  return;
  }

  // Check if seller is blocked
  final blockedUsers = await FireStoreUtils.getBlockedUsers(FireStoreUtils.getCurrentUid()!);
  if (blockedUsers.contains(ad.sellerId)) {
  ShowToastDialog.showError("You have blocked this user. Unblock them to send an offer.");
  return;
  }

  ShowToastDialog.showLoader("Sending offer...");
  final chatRoom = await FireStoreUtils.getOrCreateChatRoom(ad: ad, currentUser: Constant.userModel!);

  final msgId = Constant.getUuid();
  final message = ChatMessageModel(
  id: msgId,
  chatRoomId: chatRoom.id,
  senderId: FireStoreUtils.getCurrentUid(),
  senderName: Constant.userModel?.fullNameString() ?? '',
  senderProfile: Constant.userModel?.profilePic ?? '',
  messageType: 'offer',
  text: 'Made an offer',
  offerAmount: amount,
  offerStatus: 'pending',
  createdAt: Timestamp.now(),
  isRead: false,
  );

  final success = await FireStoreUtils.sendMessage(chatRoomId: chatRoom.id!, message: message, receiverId: chatRoom.otherUserId(FireStoreUtils.getCurrentUid()!));
  ShowToastDialog.closeLoader();

  if (success) {
  ShowToastDialog.showSuccess("Offer sent successfully!");
  Get.to(() => ChatDetailView(chatRoom: chatRoom));
  } else {
  ShowToastDialog.showError("Failed to send offer");
  }
  }

  /// Refresh controller with new ad data when navigating from seller profile,
  /// favourites, search, or any screen where controller already exists.
  /// Prevents back-navigation crashes by reusing the existing controller.
  void refreshWithAd(AdModel newAd) {
  ad = newAd;

  // Reset all observable state
  likeCount.value = newAd.likes ?? 0;
  viewCount.value = newAd.views ?? 0;
  isLiked.value = false;
  hasReported.value = false;
  existingReport.value = null;
  isSellerVerified.value = false;
  sellerRating.value = 0.0;
  sellerReviewCount.value = 0;

  // Re-initialize all data fetching
  _checkLiked();
  _incrementViews();
  _checkReportStatus();
  _checkSellerVerification();

  // Trigger GetBuilder rebuild
  update();
  }
}