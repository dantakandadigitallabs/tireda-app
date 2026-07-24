import 'dart:developer' as developer;

import 'package:eSellify/app/constant/collection_name.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SubCategoryController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<CategoryModel> categoryModel = CategoryModel().obs;
  RxList<CategoryModel> subCategoryList = <CategoryModel>[].obs;

  // Tireda Custom: search/sort support for subcategory list
  RxString searchQuery = ''.obs;
  RxList<CategoryModel> filteredList = <CategoryModel>[].obs;
  final TextEditingController searchTextController = TextEditingController();

  // Tireda Custom: distinguishes "fetch failed" from "genuinely no subcategories"
  RxBool hasError = false.obs;

  // Tireda Custom: search bar only shown when list is long enough to need it
  bool get shouldShowSearch => subCategoryList.length > 10;

  @override
  void onInit() {
    getArguments();
    super.onInit();
  }

  /// Legacy entry point: still supports the old
  /// `Get.to(..., arguments: {"category": cat})` call shape. Defensive – a
  /// missing/null/wrong-typed `category` no longer throws; we just stay in
  /// the loading state and wait for [hydrate] to be called explicitly.
  Future<void> getArguments() async {
    final args = Get.arguments;
    if (args is Map) {
      final raw = args['category'];
      if (raw is CategoryModel) {
        await hydrate(raw);
      }
    }
  }

  /// Authoritative initializer used by [SubCategoryView] when the category
  /// is passed as a constructor parameter. Idempotent: re-hydrating with
  /// the same category is a no-op.
  Future<void> hydrate(CategoryModel category) async {
    if (category.id == null || category.id!.isEmpty) return;
    if (categoryModel.value.id == category.id && subCategoryList.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    categoryModel.value = category;
    isLoading.value = true;
    hasError.value = false;
    try {
      final sub = await getSubCategories(category.id!);
      // Tireda Custom: alphabetical sort, case-insensitive
      sub.sort((a, b) => (a.categoryName ?? '').toLowerCase().compareTo((b.categoryName ?? '').toLowerCase()));
      subCategoryList.value = sub;
      filteredList.value = sub; // Tireda Custom: keep filtered list in sync with fresh fetch
      searchQuery.value = '';
    } catch (e) {
      developer.log("Error hydrating sub category: $e");
      hasError.value = true;
    } finally {
      // Tireda Custom: guarantees isLoading never gets stuck true, even on an unexpected exception
      isLoading.value = false;
    }
  }

  /// Tireda Custom: live filter for the local search bar (case-insensitive substring match on categoryName)
  void onSearchChanged(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      filteredList.value = subCategoryList;
    } else {
      final q = query.toLowerCase();
      filteredList.value = subCategoryList.where((c) => (c.categoryName ?? '').toLowerCase().contains(q)).toList();
    }
  }

  /// Fetch children for any category ID (supports N-level)
  /// Tireda Custom: errors are logged and rethrown (not swallowed) so hydrate()
  /// can distinguish "fetch failed" from "category genuinely has no children".
  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      final snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.category)
          .where("parentCategoryId", isEqualTo: parentId)
          .get();
      return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();
    } catch (e) {
      developer.log("Error to fetch Sub category: $e");
      rethrow;
    }
  }

  /// Tireda Custom: retry entry point for the error state in the view
  Future<void> retry() async {
    final cat = categoryModel.value;
    if (cat.id == null || cat.id!.isEmpty) return;
    isLoading.value = true;
    hasError.value = false;
    try {
      final sub = await getSubCategories(cat.id!);
      sub.sort((a, b) => (a.categoryName ?? '').toLowerCase().compareTo((b.categoryName ?? '').toLowerCase()));
      subCategoryList.value = sub;
      filteredList.value = sub;
      searchQuery.value = '';
    } catch (e) {
      developer.log("Error retrying sub category fetch: $e");
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if a category has children (for N-level navigation)
  Future<bool> hasChildren(String categoryId) async {
    try {
      final snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.category)
          .where("parentCategoryId", isEqualTo: categoryId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }
}