import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/modules/ads_listing/views/ads_listing_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/ad_banner_widget.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/sub_category_controller.dart';

class SubCategoryView extends StatelessWidget {
  const SubCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    // Get the category from arguments to create a unique tag
    final args = Get.arguments;
    final CategoryModel category = args != null ? args['category'] as CategoryModel : CategoryModel();
    final tag = 'sub_${category.id ?? DateTime.now().millisecondsSinceEpoch}';

    // Force a fresh controller for each category level
    final controller = Get.put(SubCategoryController(), tag: tag);

    return Obx(() => Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, controller.categoryModel.value.categoryName.toString()),
      body: Column(
        children: [
          const Center(child: AdBannerWidget()),
          Expanded(
            child: controller.isLoading.value
                ? _buildShimmer(isDark)
                : controller.subCategoryList.isEmpty
                ? _buildNoSubCategories(controller, isDark)
                : _buildSubCategoryList(controller, isDark),
          ),
        ],
      ),
    ));
  }

  /// When parent category has NO subcategories — show ads directly
  Widget _buildNoSubCategories(SubCategoryController controller, bool isDark) {
    // Navigate to ads for this parent category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cat = controller.categoryModel.value;
      Get.off(() => const AdsListingView(), arguments: {"categoryId": cat.id, "categoryName": cat.categoryName});
    });
    return const Center(child: SizedBox());
  }

  /// Subcategories in a list view
  Widget _buildSubCategoryList(SubCategoryController controller, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: controller.subCategoryList.length,
      itemBuilder: (context, index) {
        CategoryModel subCategory = controller.subCategoryList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _onCategoryTap(controller, subCategory),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
                    child: NetworkImageWidget(imageUrl: subCategory.image.toString(), fit: BoxFit.contain),
                  ),
                  spaceW(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(
                          title: subCategory.categoryName.toString(),
                          fontSize: 15,
                          fontFamily: FontFamily.medium,
                          color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                        ),
                        if (subCategory.description != null && subCategory.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: TextCustom(title: subCategory.description!, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
                          ),
                      ],
                    ),
                  ),
                  spaceW(width: 8),
                  Icon(Icons.chevron_right, size: 22, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// N-level navigation: check if category has children → drill deeper, else → show ads
  Future<void> _onCategoryTap(SubCategoryController controller, CategoryModel category) async {
    ShowToastDialog.showLoader("Loading...");
    final hasChildren = await controller.hasChildren(category.id!);
    ShowToastDialog.closeLoader();

    if (hasChildren) {
      // Has subcategories → navigate to SubCategoryView again (N-level)
      Get.to(() => const SubCategoryView(), arguments: {"category": category}, preventDuplicates: false);
    } else {
      // Leaf category → show ads
      Get.to(() => const AdsListingView(), arguments: {"categoryId": category.id, "categoryName": category.categoryName});
    }
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)),
                ),
                spaceW(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                      spaceH(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
