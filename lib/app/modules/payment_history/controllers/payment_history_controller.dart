import 'package:eSellify/app/models/transaction_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class PaymentHistoryController extends GetxController {
  RxInt selectedTab = 0.obs;
  RxBool isLoading = true.obs;

  RxList<UserSubscriptionModel> subscriptions = <UserSubscriptionModel>[].obs;
  RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    await Future.wait([_loadSubscriptions(uid), _loadTransactions(uid)]);
    isLoading.value = false;
  }

  Future<void> _loadSubscriptions(String uid) async {
    subscriptions.value = await FireStoreUtils.getUserSubscriptions(uid);
  }

  Future<void> _loadTransactions(String uid) async {
    transactions.value = await FireStoreUtils.getUserTransactions(uid);
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }
}
