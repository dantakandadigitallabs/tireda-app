import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/subscription_package_model.dart';
import 'package:eSellify/app/models/transaction_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/app/modules/payment_method/views/payment_method_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SubscriptionsController extends GetxController {
  RxInt selectedTab = 0.obs;
  RxBool isLoading = true.obs;

  RxList<SubscriptionPackageModel> adsListingPackages = <SubscriptionPackageModel>[].obs;
  RxList<SubscriptionPackageModel> featuredAdsPackages = <SubscriptionPackageModel>[].obs;

  // Active subscriptions
  Rx<UserSubscriptionModel?> activeAdListingSub = Rx<UserSubscriptionModel?>(null);
  Rx<UserSubscriptionModel?> activeFeaturedSub = Rx<UserSubscriptionModel?>(null);

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    isLoading.value = true;
    await Future.wait([
      getAdsListingSubscription(),
      getFeaturedAdsSubscription(),
      _loadActiveSubscriptions(),
    ]);
    isLoading.value = false;
  }

  Future<void> getAdsListingSubscription() async {
    final value = await FireStoreUtils.getAdsListingSubscription();
    value.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    adsListingPackages.value = value;
  }

  Future<void> getFeaturedAdsSubscription() async {
    final value = await FireStoreUtils.getFeaturedAdsSubscription();
    value.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    featuredAdsPackages.value = value;
  }

  Future<void> _loadActiveSubscriptions() async {
    final uid = currentUserId;
    if (uid == null) return;
    activeAdListingSub.value = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');
    activeFeaturedSub.value = await FireStoreUtils.getActiveSubscription(uid, 'featured_ads');
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  /// Purchase a package — free plans skip payment screen
  Future<void> purchasePackage(SubscriptionPackageModel package) async {
    final price = package.finalPrice ?? package.price ?? 0;

    if (price <= 0) {
      // Free plan — direct purchase without payment
      await _directFreePurchase(package);
    } else {
      // Paid plan — navigate to payment screen
      final result = await Get.to(() => const PaymentMethodView(), arguments: package);
      if (result == true) await getData();
    }
  }

  /// Directly activate a free package (no payment needed)
  Future<void> _directFreePurchase(SubscriptionPackageModel package) async {
    final uid = currentUserId;
    if (uid == null) {
      ShowToastDialog.showError("Please login to continue");
      return;
    }

    ShowToastDialog.showLoader("Activating plan...");

    // Cancel any existing active subscription of the same type
    await FireStoreUtils.cancelActiveSubscriptions(uid, package.type ?? 'ad_listing');

    try {
      final subscriptionId = Constant.getUuid();
      final transactionId = Constant.getUuid();
      final packageName = package.name?.values.firstOrNull ?? '';

      // Count current active ads
      final currentActiveAds = package.type == 'featured_ads'
          ? await FireStoreUtils.countUserFeaturedAds(uid)
          : await FireStoreUtils.countUserActiveAds(uid);

      Timestamp? expiryDate;
      if (package.isUnlimited != true && package.packageDuration != null) {
        expiryDate = Timestamp.fromDate(DateTime.now().add(Duration(days: package.packageDuration!)));
      }

      final subscription = UserSubscriptionModel(
        id: subscriptionId,
        userId: uid,
        packageId: package.id,
        packageName: packageName,
        packageImage: package.image,
        packageType: package.type,
        price: 0,
        status: 'active',
        purchaseDate: Timestamp.now(),
        expiryDate: expiryDate,
        adsPosted: currentActiveAds,
        adLimit: package.itemLimit ?? 0,
        isItemLimitUnlimited: package.isItemLimitUnlimited ?? false,
        listingDurationType: package.listingDurationType,
        customDuration: package.customDuration,
        packageDuration: package.packageDuration,
        paymentId: transactionId,
        paymentMethod: 'free',
      );

      final transaction = TransactionModel(
        id: transactionId,
        userId: uid,
        userName: Constant.userModel?.fullNameString(),
        userEmail: Constant.userModel?.email,
        packageId: package.id,
        packageName: packageName,
        packageType: package.type,
        amount: 0,
        currency: Constant.currencyModel?.symbol ?? '\$',
        paymentMethod: 'free',
        paymentStatus: 'success',
        transactionId: 'free_$subscriptionId',
        subscriptionId: subscriptionId,
        createdAt: Timestamp.now(),
      );

      await Future.wait([
        FireStoreUtils.createUserSubscription(subscription),
        FireStoreUtils.createTransaction(transaction),
      ]);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showSuccess("Plan activated successfully!");
      await getData();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Failed to activate plan: $e");
    }
  }

  /// Check if a package is the user's active subscription
  bool isActivePlan(SubscriptionPackageModel package) {
    if (package.type == 'ad_listing') {
      return activeAdListingSub.value?.packageId == package.id && activeAdListingSub.value?.isActive == true;
    } else {
      return activeFeaturedSub.value?.packageId == package.id && activeFeaturedSub.value?.isActive == true;
    }
  }
}
