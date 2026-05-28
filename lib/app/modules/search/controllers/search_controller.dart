import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdSearchController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  RxString query = ''.obs;
  RxBool isSearching = false.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxList<AdModel> searchResults = <AdModel>[].obs;
  RxList<String> recentSearches = <String>[].obs;
  RxList<CategoryModel> categories = <CategoryModel>[].obs;

  Timer? _debounce;
  DocumentSnapshot? _lastDocument;

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;


  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _loadCategories();
    scrollController.addListener(_onScroll);
    Future.delayed(const Duration(milliseconds: 300), () {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  void onSearchChanged(String value) {
    query.value = value.trim();
    _debounce?.cancel();

    if (query.value.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      hasMore.value = true;
      _lastDocument = null;
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.value);
    });
  }

  Future<void> _performSearch(String searchQuery) async {
    if (searchQuery.isEmpty) return;

    isSearching.value = true;
    _lastDocument = null;
    hasMore.value = true;

    try {
      final result = await FireStoreUtils.getActiveAdsPaginated(
        limit: Constant.pageSize,
        searchQuery: searchQuery,
      );
      searchResults.value = result.items;
      _lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
    } catch (e) {
      developer.log('Search error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || query.value.isEmpty) return;

    isLoadingMore.value = true;
    try {
      final result = await FireStoreUtils.getActiveAdsPaginated(
        limit: Constant.pageSize,
        lastDocument: _lastDocument,
        searchQuery: query.value,
      );
      searchResults.addAll(result.items);
      _lastDocument = result.lastDocument;
      hasMore.value = result.hasMore;
    } catch (e) {
      developer.log('Load more search error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void submitSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _saveRecentSearch(trimmed);
  }

  void onRecentSearchTap(String search) {
    searchController.text = search;
    query.value = search;
    _performSearch(search);
    _saveRecentSearch(search);
  }

  void clearSearch() {
    searchController.clear();
    query.value = '';
    searchResults.clear();
    isSearching.value = false;
    hasMore.value = true;
    _lastDocument = null;
    searchFocusNode.requestFocus();
  }

  // ─── Recent Searches ──────────────────────────────────────────

  void _loadRecentSearches() {
    final stored = Preferences.getString(_recentSearchesKey);
    if (stored.isNotEmpty) {
      recentSearches.value = List<String>.from(jsonDecode(stored));
    }
  }

  void _saveRecentSearch(String search) {
    recentSearches.remove(search);
    recentSearches.insert(0, search);
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.removeLast();
    }
    Preferences.setString(_recentSearchesKey, jsonEncode(recentSearches));
  }

  void removeRecentSearch(String search) {
    recentSearches.remove(search);
    Preferences.setString(_recentSearchesKey, jsonEncode(recentSearches));
  }

  void clearAllRecentSearches() {
    recentSearches.clear();
    Preferences.setString(_recentSearchesKey, jsonEncode([]));
  }

  // ─── Categories ───────────────────────────────────────────────

  Future<void> _loadCategories() async {
    try {
      categories.value = await FireStoreUtils.getParentCategory();
    } catch (_) {}
  }
}
