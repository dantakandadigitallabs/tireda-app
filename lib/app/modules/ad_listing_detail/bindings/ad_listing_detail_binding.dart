import 'package:get/get.dart';
import '../controllers/ad_listing_detail_controller.dart';

class AdListingDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdListingDetailController>(
          () => AdListingDetailController(),
      fenix: true,
    );
  }
}