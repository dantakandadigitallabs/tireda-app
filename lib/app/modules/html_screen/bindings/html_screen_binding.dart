import 'package:get/get.dart';

import '../controllers/html_screen_controller.dart';

class HtmlScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HtmlScreenController>(
      () => HtmlScreenController(),
    );
  }
}
