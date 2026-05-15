import 'dart:developer';

import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class FavouritesController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<AdModel> favouriteAds = <AdModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavourites();
  }

  Future<void> loadFavourites() async {
    isLoading.value = true;
    try {
      final uid = FireStoreUtils.getCurrentUid();
      if (uid != null) {
        favouriteAds.value = await FireStoreUtils.getUserFavouriteAds(uid);
      }
    } catch (e) {
      log('Error loading favourites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(AdModel ad) async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null || ad.id == null) return;

    final result = await FireStoreUtils.toggleLike(ad.id!, uid);
    if (!result) {
      // Unliked — remove from list
      favouriteAds.removeWhere((e) => e.id == ad.id);
      favouriteAds.refresh();
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
