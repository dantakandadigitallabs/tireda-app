import 'package:get/get.dart';
import '../controllers/my_purchases_controller.dart';

class MyPurchasesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyPurchasesController>(() => MyPurchasesController());
  }
}
