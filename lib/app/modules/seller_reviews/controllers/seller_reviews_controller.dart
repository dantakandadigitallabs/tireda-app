import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/review_model.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SellerReviewsController extends GetxController {
  // ── Existing ─────────────────────────────────────────────
  RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  RxBool isLoading = true.obs;
  RxDouble averageRating = 0.0.obs;
  RxInt reviewCount = 0.obs;
  RxString sellerName = ''.obs;
  String sellerId = '';

  // ── New — seller profile + listings ──────────────────────
  Rx<UserModel?> sellerModel = Rx<UserModel?>(null);
  RxList<AdModel> sellerAds = <AdModel>[].obs;
  RxBool isAdsLoading = true.obs;
  RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      sellerId = args['sellerId'] ?? '';
      sellerName.value = args['sellerName'] ?? 'Seller';
    }
    if (sellerId.isNotEmpty) {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadSellerProfile(),
      _loadReviews(),
      _loadSellerAds(),
    ]);
  }

  Future<void> _loadSellerProfile() async {
    try {
      final user = await FireStoreUtils.getUserProfile(sellerId);
      if (user != null) {
        sellerModel.value = user;
        sellerName.value = user.fullNameString();
      }
    } catch (_) {}
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

  Future<void> _loadSellerAds() async {
    isAdsLoading.value = true;
    try {
      final ads = await FireStoreUtils.getMyAds(sellerId);
      // Only show active ads on public profile
      sellerAds.value = ads.where((a) => a.status == 'active').toList();
    } catch (_) {}
    isAdsLoading.value = false;
  }

  /// Member since — formatted from createdAt
  String get memberSince {
    final user = sellerModel.value;
    if (user == null) return '';
    try {
      final dt = user.createdAt?.toDate();
      if (dt == null) return '';
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Joined ${months[dt.month - 1]}. ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String formatPrice(AdModel ad) {
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
    final c = ad.currency;
    final s = c?.symbol ?? '';
    final d = c?.decimalDigits ?? 0;
    final p = ad.price!.toStringAsFixed(d);
    return c?.symbolAtRight == true ? "$p $s".trim() : "$s$p".trim();
  }
}