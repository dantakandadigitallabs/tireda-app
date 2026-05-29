import 'dart:async';
import 'dart:developer';

import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/banner_model.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/feature_section_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/app/modules/ads_listing/views/ads_listing_view.dart';
import 'package:eSellify/app/modules/sub_category/views/sub_category_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eSellify/utils/navigation_helper.dart';

class HomeController extends GetxController {
  Rx<TextEditingController> searchController = TextEditingController().obs;
  RxBool isSearchFocused = false.obs;

  RxList<CategoryModel> categoryList = <CategoryModel>[].obs;

  // Feature sections
  RxList<FeatureSectionModel> featureSections = <FeatureSectionModel>[].obs;
  RxMap<String, List<AdModel>> sectionAds = <String, List<AdModel>>{}.obs;
  RxBool isSectionsLoading = true.obs;

  // Banners
  RxList<BannerModel> bannerList = <BannerModel>[].obs;
  RxBool isBannersLoading = true.obs;
  final PageController bannerPageController = PageController();
  RxInt currentBannerIndex = 0.obs;
  Timer? _autoScrollTimer;

  // "All Ads" preview shown on home — uses the same paginated query as the
  // ads listing page (respects location + maxRange + status=active filters).
  RxList<AdModel> allAdsPreview = <AdModel>[].obs;
  RxBool isAllAdsLoading = true.obs;

  // Notification dot — true when user has at least one unread notification
  RxBool hasUnreadNotifications = false.obs;
  StreamSubscription? _notificationsSubscription;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  @override
  void onClose() {
    _autoScrollTimer?.cancel();
    _notificationsSubscription?.cancel();
    bannerPageController.dispose();
    super.onClose();
  }

  void getData() {
    getCategory();
    loadFeatureSections();
    loadBanners();
    loadAllAdsPreview();
    _listenToUnreadNotifications();
  }

  /// Listens to the notifications stream and updates [hasUnreadNotifications]
  /// reactively. Uses the same stream as NotificationsController so no
  /// extra Firestore reads are introduced beyond what already exists.
  void _listenToUnreadNotifications() {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return;

    _notificationsSubscription?.cancel();
    _notificationsSubscription = FireStoreUtils.getNotificationsStream(uid).listen(
          (list) {
        hasUnreadNotifications.value = list.any((n) => n.isRead != true);
      },
      onError: (e) {
        log('Error listening to notifications stream: $e');
      },
    );
  }

  /// Loads a small preview of all active ads for the "All Ads" home section.
  /// Uses the same paginated query as the listing page so filters stay
  /// consistent (status=active, distance within admin maxRange, etc.).
  /// "View all" on this section pushes the user to the full listing page.
  Future<void> loadAllAdsPreview() async {
    isAllAdsLoading.value = true;
    try {
      final result = await FireStoreUtils.getActiveAdsPaginated(limit: 6);
      allAdsPreview.assignAll(result.items);
    } catch (e) {
      log('Error loading all ads preview: $e');
    } finally {
      isAllAdsLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    // Search is handled on submit, not on every keystroke
  }

  void onSearchSubmit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    searchController.value.clear();
    Get.to(() => const AdsListingView(), arguments: {"searchQuery": query});
  }

  Future<void> getCategory() async {
    final category = await FireStoreUtils.getParentCategory();
    categoryList.value = category;
  }

  Future<void> loadFeatureSections() async {
    isSectionsLoading.value = true;
    try {
      final sections = await FireStoreUtils.getActiveFeatureSections();

      // Sort: featured_ads sections first, then by sortOrder
      sections.sort((a, b) {
        if (a.filterType == 'featured_ads' && b.filterType != 'featured_ads') return -1;
        if (a.filterType != 'featured_ads' && b.filterType == 'featured_ads') return 1;
        return (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
      });

      featureSections.value = sections;

      // Load all section ads in parallel first
      final futures = sections.map((section) async {
        try {
          return MapEntry(section.id!, await FireStoreUtils.getAdsForSection(section));
        } catch (e) {
          log('Error loading ads for section ${section.id}: $e');
          return MapEntry(section.id!, <AdModel>[]);
        }
      });

      final results = await Future.wait(futures);

      // Same ad can appear in multiple sections (each section is a different filter lens)
      for (final entry in results) {
        sectionAds[entry.key] = entry.value;
      }

      sectionAds.refresh();
    } catch (e) {
      log('Error loading feature sections: $e');
    } finally {
      isSectionsLoading.value = false;
    }
  }

  // ── Banners ─────────────────────────────────────────────────────────

  Future<void> loadBanners() async {
    isBannersLoading.value = true;
    try {
      bannerList.value = await FireStoreUtils.getActiveBanners();
      _startAutoScroll();
    } catch (e) {
      log('Error loading banners: $e');
    } finally {
      isBannersLoading.value = false;
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (bannerList.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!bannerPageController.hasClients) return;
      final nextPage = (currentBannerIndex.value + 1) % bannerList.length;
      bannerPageController.animateToPage(nextPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  void onBannerPageChanged(int index) {
    currentBannerIndex.value = index;
  }

  Future<void> onBannerTap(BannerModel banner) async {
    if (banner.redirectType == null || banner.redirectValue == null || banner.redirectValue!.isEmpty) return;

    switch (banner.redirectType) {
      case 'category':
        final category = await FireStoreUtils.getCategoryById(banner.redirectValue!);
        if (category != null) {
          Get.to(() => const SubCategoryView(), arguments: {"category": category});
        }
        break;

      case 'external_link':
        final uri = Uri.tryParse(banner.redirectValue!);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;

      case 'ad_detail':
        final ad = await FireStoreUtils.getAdById(banner.redirectValue!);
        if (ad != null) {
          goToAdDetail(ad);
        }
        break;
    }
  }
}