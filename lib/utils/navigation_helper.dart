import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/controllers/ad_listing_detail_controller.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:get/get.dart';

/// Navigate to ad detail.
/// If controller exists from previous ad, refreshes it with new ad data
/// instead of deleting and recreating, preventing back-navigation crashes.
void goToAdDetail(AdModel ad) {
  if (Get.isRegistered<AdListingDetailController>()) {
    final controller = Get.find<AdListingDetailController>();
    controller.refreshWithAd(ad);
  }
  Get.to(() => const AdListingDetailView(), arguments: {"ad": ad});
}