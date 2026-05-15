import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class BlockedUsersController extends GetxController {
  RxList<UserModel> blockedUsers = <UserModel>[].obs;
  RxBool isLoading = true.obs;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  @override
  void onInit() {
    super.onInit();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    try {
      final blockedIds = await FireStoreUtils.getBlockedUsers(uid);
      if (blockedIds.isEmpty) {
        isLoading.value = false;
        return;
      }
      final profiles = await FireStoreUtils.getUserProfiles(blockedIds);
      blockedUsers.value = profiles;
    } catch (_) {}

    isLoading.value = false;
  }

  Future<bool> unblockUser(String blockedUserId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final success = await FireStoreUtils.unblockUser(uid, blockedUserId);
    if (success) {
      blockedUsers.removeWhere((u) => u.id == blockedUserId);
    }
    return success;
  }
}
