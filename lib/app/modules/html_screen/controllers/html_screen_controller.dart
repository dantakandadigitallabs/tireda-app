import 'package:get/get.dart';
import 'package:eSellify/app/constant/constants.dart';

class HtmlScreenController extends GetxController {
  final title = ''.obs;
  final content = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map<String, String>) {
      title.value = args['title'] ?? '';
      final type = args['type'] ?? '';
      switch (type) {
        case 'privacy':
          content.value = Constant.privacyPolicy;
          break;
        case 'terms':
          content.value = Constant.termsAndConditions;
          break;
        case 'about':
          content.value = Constant.aboutApp;
          break;
        default:
          content.value = '';
      }
    }
  }
}
