import 'dart:developer';

import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Added intl import

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
    if (ad.isJobAd) return ad.formattedSalary();
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";

    final currency = ad.currency;
    final symbol = currency?.symbol ?? '';
    final decimals = currency?.decimalDigits ?? 0;

    // Use NumberFormat to add the thousands separator
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: decimals,
    );

    final formattedPrice = formatter.format(ad.price).trim();

    if (currency?.symbolAtRight == true) return "$formattedPrice $symbol".trim();
    return "$symbol$formattedPrice".trim();
  }
}