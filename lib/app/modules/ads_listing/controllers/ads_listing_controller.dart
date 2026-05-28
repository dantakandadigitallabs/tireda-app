import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/feature_section_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdsListingController extends GetxController {
  RxString title = ''.obs;
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;

  // Data
  RxList<AdModel> allAds = <AdModel>[].obs;
  RxList<AdModel> filteredAds = <AdModel>[].obs;
  Rx<FeatureSectionModel?> section = Rx<FeatureSectionModel?>(null);
  DocumentSnapshot? _lastDocument;

  /// Count of active ads per category ID — reflects ALL ads in DB
  /// (not just the current page), so filter counts are always accurate.
  RxMap<String, int> categoryCounts = <String, int>{}.obs;

  // Scroll controller for infinite-scroll pagination
  final ScrollController scrollController = ScrollController();

  // View mode: 0 = list, 1 = grid
  RxInt viewMode = 0.obs;

  // Search
  final TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;

  // Sort
  RxString sortBy = 'popular'.obs;
  static const List<Map<String, String>> sortOptions = [
    {'key': 'popular', 'label': 'Popular'},
    {'key': 'new_to_old', 'label': 'New to Old'},
    {'key': 'old_to_new', 'label': 'Old to New'},
    {'key': 'price_high', 'label': 'Price High to Low'},
    {'key': 'price_low', 'label': 'Price Low to High'},
  ];

  // Filter
  RxString filterCategoryId = ''.obs;
  RxString filterCategoryName = ''.obs;
  Rx<double?> filterMinPrice = Rx<double?>(null);
  Rx<double?> filterMaxPrice = Rx<double?>(null);
  RxString filterPostedSince = 'all'.obs;
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  // Categories for filter
  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;

  static const List<Map<String, String>> postedSinceOptions = [
    {'key': 'all', 'label': 'All Time'},
    {'key': '24h', 'label': 'Last 24 Hours'},
    {'key': '7d', 'label': 'Last 7 Days'},
    {'key': '30d', 'label': 'Last 30 Days'},
  ];

  // Category filter from navigation
  String? _argCategoryId;
  bool _isFeatureSection = false;

  // Tracks last-seen location coords so we only refetch on real changes
  String? _lastKnownLocationKey;
  String _locationKey(dynamic loc) {
    final lat = loc?.location?.latitude;
    final lng = loc?.location?.longitude;
    return '$lat|$lng';
  }

  /// Count ads matching a category. Reads from the full-DB counts map so
  /// numbers are accurate regardless of pagination state.
  int countAdsForCategory(String categoryId) {
    return categoryCounts[categoryId] ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      final text = searchController.text;
      if (text == searchQuery.value) return; // prevent loop
      searchQuery.value = text;
      _fetchAds();
    });
    scrollController.addListener(_onScroll);

    // Refetch on real location changes only; ignore same-value reassigns
    // that would stomp pagination state mid-session.
    _lastKnownLocationKey = _locationKey(Constant.currentLocation.value);
    ever(Constant.currentLocation, (loc) {
      final key = _locationKey(loc);
      if (key == _lastKnownLocationKey) return;
      _lastKnownLocationKey = key;
      _fetchAds();
      _loadCategoryCounts();
    });

    _loadArguments();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    // Trigger load when we're within 200px of the bottom.
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  void _loadArguments() {
    final args = Get.arguments;
    if (args != null && args['section'] != null) {
      section.value = args['section'] as FeatureSectionModel;
      title.value = section.value!.title ?? 'Ads';
      _isFeatureSection = true;
    } else if (args != null && args['categoryId'] != null) {
      _argCategoryId = args['categoryId'] as String;
      title.value = args['categoryName'] ?? 'Ads';
      filterCategoryId.value = _argCategoryId!;
      filterCategoryName.value = args['categoryName'] ?? '';
    } else if (args != null && args['searchQuery'] != null) {
      final query = args['searchQuery'] as String;
      searchController.text = query;
      searchQuery.value = query;
      title.value = 'Search Results';
    } else {
      title.value = 'All Ads';
    }
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([_fetchAds(), _loadCategories(), _loadCategoryCounts()]);
    } catch (e) {
      log('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final counts = await FireStoreUtils.getCategoryCounts();
      categoryCounts.assignAll(counts);
    } catch (e) {
      log('Error loading category counts: $e');
    }
  }

  /// Effective category id for server-side querying. Filter UI wins over
  /// the nav-arg if user changes it.
  String? get _effectiveCategoryId {
    if (filterCategoryId.value.isNotEmpty) return filterCategoryId.value;
    return _argCategoryId;
  }

  DateTime? get _postedSinceCutoff {
    switch (filterPostedSince.value) {
      case '24h': return DateTime.now().subtract(const Duration(hours: 24));
      case '7d':  return DateTime.now().subtract(const Duration(days: 7));
      case '30d': return DateTime.now().subtract(const Duration(days: 30));
      default:    return null;
    }
  }

  Future<void> _fetchAds() async {
    isLoading.value = true;
    try {
      _lastDocument = null;
      hasMore.value = true;

      final result = await FireStoreUtils.getActiveAdsPaginated(
        limit: Constant.pageSize,
        categoryId: _effectiveCategoryId,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        section: _isFeatureSection ? section.value : null,
        minPrice: filterMinPrice.value,
        maxPrice: filterMaxPrice.value,
        postedSinceCutoff: _postedSinceCutoff,
      );
      allAds.value = result.items;
      _lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
      _applyFilters();
    } catch (e) {
      log('Error fetching ads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches the next page from Firestore using cursor pagination.
  /// Triggered by the scroll listener when near the bottom.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final result = await FireStoreUtils.getActiveAdsPaginated(
        limit: Constant.pageSize,
        lastDocument: _lastDocument,
        categoryId: _effectiveCategoryId,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        section: _isFeatureSection ? section.value : null,
        minPrice: filterMinPrice.value,
        maxPrice: filterMaxPrice.value,
        postedSinceCutoff: _postedSinceCutoff,
      );

      allAds.addAll(result.items);
      _lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
      _applyFilters();
    } catch (e) {
      log('Error loading more ads: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Public method to refetch ads from scratch (page 1).
  /// NOTE: Do NOT name this `refresh` — that would override GetxController's
  /// internal `refresh()` called during `update()`, causing an infinite loop.
  Future<void> refetch() async {
    await _fetchAds();
  }

  Future<void> _loadCategories() async {
    try {
      allCategories.value = await FireStoreUtils.getParentCategory();
    } catch (_) {}
  }

  /// All filtering (search, category, price, posted-since) is applied
  /// server-side in `getActiveAdsPaginated`. Just mirror the result without
  /// re-sorting so infinite scroll correctly APPENDS new items instead of
  /// reshuffling.
  void _applyFilters() {
    filteredAds.assignAll(allAds);
    update();
  }

  void setSortBy(String key) {
    if (sortBy.value == key) return;
    sortBy.value = key;
    // Sort is a full-dataset concern — restart pagination.
    _fetchAds();
  }

  void selectCategory(String categoryId, String categoryName) {
    filterCategoryId.value = categoryId;
    filterCategoryName.value = categoryName;
    _argCategoryId = null; // filter UI wins
    title.value = categoryName.isNotEmpty ? categoryName : 'All Ads';
    _fetchAds();
  }

  void applyFilter() {
    filterMinPrice.value = double.tryParse(minPriceController.text.trim());
    filterMaxPrice.value = double.tryParse(maxPriceController.text.trim());

    if (filterCategoryId.value.isEmpty && _argCategoryId != null) {
      _argCategoryId = null;
      title.value = 'All Ads';
    } else if (filterCategoryId.value.isNotEmpty) {
      title.value = filterCategoryName.value.isNotEmpty ? filterCategoryName.value : 'All Ads';
    }
    _fetchAds();
  }

  void resetFilter() {
    filterCategoryId.value = '';
    filterCategoryName.value = '';
    filterMinPrice.value = null;
    filterMaxPrice.value = null;
    filterPostedSince.value = 'all';
    minPriceController.clear();
    maxPriceController.clear();
    _argCategoryId = null;
    title.value = 'All Ads';
    _fetchAds();
  }

  bool get hasActiveFilter =>
      filterCategoryId.value.isNotEmpty ||
      filterMinPrice.value != null ||
      filterMaxPrice.value != null ||
      filterPostedSince.value != 'all';

  @override
  void onClose() {
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
