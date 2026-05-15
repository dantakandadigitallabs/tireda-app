import 'package:get/get.dart';

import '../controllers/blocked_users_controller.dart';

class BlockedUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlockedUsersController>(
      () => BlockedUsersController(),
    );
  }
}
