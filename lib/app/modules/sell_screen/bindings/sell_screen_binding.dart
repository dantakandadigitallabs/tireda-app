import 'package:get/get.dart';

import '../controllers/sell_screen_controller.dart';

class SellScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellScreenController>(
      () => SellScreenController(),
    );
  }
}
