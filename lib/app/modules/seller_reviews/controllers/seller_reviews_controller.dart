import 'package:eSellify/app/models/review_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SellerReviewsController extends GetxController {
  RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  RxBool isLoading = true.obs;
  RxDouble averageRating = 0.0.obs;
  RxInt reviewCount = 0.obs;
  RxString sellerName = ''.obs;
  String sellerId = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      sellerId = args['sellerId'] ?? '';
      sellerName.value = args['sellerName'] ?? 'Seller';
    }
    if (sellerId.isNotEmpty) _loadReviews();
  }

  Future<void> _loadReviews() async {
    isLoading.value = true;
    try {
      reviews.value = await FireStoreUtils.getSellerReviews(sellerId);
      final ratingData = await FireStoreUtils.getSellerRating(sellerId);
      averageRating.value = ratingData['average'] ?? 0.0;
      reviewCount.value = ratingData['count'] ?? 0;
    } catch (_) {}
    isLoading.value = false;
  }
}
