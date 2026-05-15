import 'package:get/get.dart';
import '../controllers/ads_listing_controller.dart';

class AdsListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdsListingController>(() => AdsListingController());
  }
}
