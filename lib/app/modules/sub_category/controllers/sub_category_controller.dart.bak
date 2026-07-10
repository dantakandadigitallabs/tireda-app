import 'dart:developer' as developer;

import 'package:eSellify/app/constant/collection_name.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SubCategoryController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<CategoryModel> categoryModel = CategoryModel().obs;
  RxList<CategoryModel> subCategoryList = <CategoryModel>[].obs;

  @override
  void onInit() {
    getArguments();
    super.onInit();
  }

  Future<void> getArguments() async {
    dynamic arguments = Get.arguments;
    if (arguments != null) {
      categoryModel.value = arguments['category'];
      final subcategory = await getSubCategories(categoryModel.value.id!);
      subCategoryList.value = subcategory;
      isLoading.value = false;
    }
  }

  /// Fetch children for any category ID (supports N-level)
  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      final snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.category)
          .where("parentCategoryId", isEqualTo: parentId)
          .get();
      return snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();
    } catch (e) {
      developer.log("Error to fetch Sub category: $e");
      return [];
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
}
