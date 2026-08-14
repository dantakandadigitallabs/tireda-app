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

  // Tireda Custom: tracks whether the user has ever redeemed a free plan for
  // each packageType — used purely for UI (greying out "Buy Again" on free
  // packages). The actual enforcement still happens in purchasePackage() via
  // FireStoreUtils.hasUsedFreePlan(); this is just so the button can reflect
  // that state without the user needing to tap first and get a toast.
  //
  // NOTE: 1.5 base replaced this with per-packageId tracking
  // (usedFreePackageIds / hasUsedFreePackage). NOT taken — Tireda's model
  // intentionally tracks free-plan usage per packageType, not per specific
  // package, so switching to per-package tracking would let a user reclaim
  // a "free" allowance by picking a different free package of the same type.
  RxBool usedFreeAdListing = false.obs;
  RxBool usedFreeFeaturedAds = false.obs;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  bool get showAdListing => !Constant.freeAdListing;
  bool get showFeaturedAds => !Constant.freeAdFeaturing;

  @override
  void onInit() {
    if (!showAdListing && showFeaturedAds) {
      selectedTab.value = 1;
    }
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    isLoading.value = true;
    final futures = <Future>[_loadActiveSubscriptions()];
    if (showAdListing) futures.add(getAdsListingSubscription());
    if (showFeaturedAds) futures.add(getFeaturedAdsSubscription());
    await Future.wait(futures);
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
    // Tireda Custom: prefetch free-plan-used state for button greying (see field comments above).
    usedFreeAdListing.value = await FireStoreUtils.hasUsedFreePlan(uid, 'ad_listing');
    usedFreeFeaturedAds.value = await FireStoreUtils.hasUsedFreePlan(uid, 'featured_ads');
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  /// Purchase a package — free plans skip payment screen
  Future<void> purchasePackage(SubscriptionPackageModel package) async {
    final price = package.finalPrice ?? package.price ?? 0;

    if (price <= 0) {
      // Tireda Custom: block repeat free-plan activation — see hasUsedFreePlan().
      final uid = currentUserId;
      if (uid != null) {
        final alreadyUsed = await FireStoreUtils.hasUsedFreePlan(uid, package.type ?? 'ad_listing');
        if (alreadyUsed) {
          ShowToastDialog.showError("You've already used your free plan for this type. Please choose a paid plan.".tr);
          return;
        }
      }
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
      ShowToastDialog.showError("Please login to continue".tr);
      return;
    }

    ShowToastDialog.showLoader("Activating plan...".tr);

    // Tireda Custom: additive upgrade — merge unused allowance from any existing
    // active subscription of this type into the new one, instead of discarding it.
    // See FireStoreUtils.mergeOrCreateSubscription() for full rationale.
    // NOTE: 1.5 base replaced this with cancelActiveSubscriptions() (destructive
    // replace, discards unused allowance). NOT taken — conflicts directly with
    // Tireda's additive subscription model.
    final carriedAllowance = await FireStoreUtils.mergeOrCreateSubscription(
      userId: uid,
      packageType: package.type ?? 'ad_listing',
    );

    try {
      final subscriptionId = Constant.getUuid();
      final transactionId = Constant.getUuid();
      // Tireda Custom Merge (eSellify 1.5): snapshot the whole per-language
      // name map from the package so downstream docs (user_subscriptions +
      // transactions) can render in any language later. Flat `packageName`
      // stays populated for legacy readers. Replaces the previous
      // `package.name?.values.firstOrNull` (arbitrary language, no fallback
      // order) with a proper default → en → first-non-empty resolution.
      final Map<String, String>? packageNameMap = (package.name != null && package.name!.isNotEmpty)
          ? Map<String, String>.from(package.name!)
          : null;
      final packageName = (packageNameMap?['default'] ?? '').isNotEmpty
          ? packageNameMap!['default']!
          : (packageNameMap?['en'] ?? packageNameMap?.values.firstOrNull ?? '');

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
        packageNameTranslations: packageNameMap,
        packageImage: package.image,
        packageType: package.type,
        price: 0,
        status: 'active',
        purchaseDate: Timestamp.now(),
        expiryDate: expiryDate,
        adsPosted: currentActiveAds,
        // Tireda Custom: add carried-forward unused allowance from the previous
        // active subscription (0 if none existed, or if it was unlimited).
        // If this new package itself is unlimited, isItemLimitUnlimited handles that
        // case and adLimit becomes irrelevant/unused downstream.
        adLimit: (package.itemLimit ?? 0) + carriedAllowance,
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
        packageNameTranslations: packageNameMap,
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
      ShowToastDialog.showSuccess("Plan activated successfully!".tr);
      await getData();
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("${"Failed to activate plan".tr}: $e");
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