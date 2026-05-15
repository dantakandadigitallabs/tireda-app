import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/review_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class MyPurchasesController extends GetxController {
  RxList<AdModel> purchases = <AdModel>[].obs;
  RxBool isLoading = true.obs;

  // Track which ads have been reviewed
  RxSet<String> reviewedAdIds = <String>{}.obs;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  @override
  void onInit() {
    super.onInit();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    purchases.value = await FireStoreUtils.getMyPurchases(uid);

    // Check which ads have been reviewed
    for (final ad in purchases) {
      if (ad.id != null) {
        final reviewed = await FireStoreUtils.hasReviewedForAd(uid, ad.id!);
        if (reviewed) reviewedAdIds.add(ad.id!);
      }
    }
    isLoading.value = false;
  }

  bool isReviewed(String adId) => reviewedAdIds.contains(adId);

  Future<void> submitReview({
    required AdModel ad,
    required double rating,
    required String comment,
  }) async {
    final uid = currentUserId;
    if (uid == null || ad.sellerId == null) return;

    final review = ReviewModel(
      id: Constant.getUuid(),
      sellerId: ad.sellerId,
      sellerName: ad.sellerName,
      buyerId: uid,
      buyerName: Constant.userModel?.fullNameString(),
      buyerProfile: Constant.userModel?.profilePic,
      adId: ad.id,
      adTitle: ad.title,
      adImage: ad.mainImage,
      rating: rating,
      comment: comment.trim().isNotEmpty ? comment.trim() : null,
      createdAt: Timestamp.now(),
    );

    ShowToastDialog.showLoader("Submitting review...");
    final success = await FireStoreUtils.submitReview(review);
    ShowToastDialog.closeLoader();

    if (success) {
      reviewedAdIds.add(ad.id!);
      ShowToastDialog.showSuccess("Review submitted!");
    } else {
      ShowToastDialog.showError("Failed to submit review");
    }
  }
}
