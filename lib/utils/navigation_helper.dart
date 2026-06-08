import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/controllers/ad_listing_detail_controller.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:get/get.dart';

/// Navigate to ad detail from OUTSIDE the detail page (home, search,
/// seller profile, favourites, etc.).
/// If a controller already exists from a previous navigation, refreshes it
/// with the new ad data instead of deleting and recreating, preventing
/// back-navigation crashes on seller profile → ad detail flows.
void goToAdDetail(AdModel ad) {
  if (Get.isRegistered<AdListingDetailController>()) {
    final controller = Get.find<AdListingDetailController>();
    controller.refreshWithAd(ad);
  }
  Get.to(() => AdListingDetailView(ad: ad));
}

/// Navigate to ad detail FROM WITHIN the detail page (similar ads).
/// Each similar-ad page owns its controller as a StatefulWidget local
/// instance — no GetX registry involved — so the full navigation stack
/// (A → B → C → back → B → back → A) works correctly.
void goToSimilarAdDetail(AdModel ad) {
  Get.to(
        () => AdListingDetailView(ad: ad),
    preventDuplicates: false,
  );
}