import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CategoriesController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<CategoryModel> categoryList = <CategoryModel>[].obs;

  @override
  void onInit() {
    getCategory();
    super.onInit();
  }

  Future<void> getCategory() async {
    final category = await FireStoreUtils.getParentCategory();
    categoryList.value = category;
    isLoading.value = false;
  }
}
