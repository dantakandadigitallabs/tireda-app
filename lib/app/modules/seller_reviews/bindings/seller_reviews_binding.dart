import 'package:get/get.dart';
import '../controllers/seller_reviews_controller.dart';

class SellerReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerReviewsController>(() => SellerReviewsController());
  }
}
