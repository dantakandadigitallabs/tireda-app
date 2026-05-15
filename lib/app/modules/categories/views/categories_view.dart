import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/modules/sub_category/views/sub_category_view.dart';
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

import '../controllers/categories_controller.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX(
      init: CategoriesController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Categories"),
          body: Column(
            children: [
              const Center(child: AdBannerWidget()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: controller.isLoading.value
                ? _buildShimmer(isDark)
                : controller.categoryList.isEmpty
                    ? Center(child: TextCustom(title: "No Categories Found"))
                    : GridView.builder(
                        itemCount: controller.categoryList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, index) {
                          CategoryModel category = controller.categoryList[index];
                          return InkWell(
                            onTap: () => Get.to(() => const SubCategoryView(), arguments: {"category": category}),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: NetworkImageWidget(imageUrl: category.image.toString(), fit: BoxFit.contain),
                                  ),
                                  spaceH(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: TextCustom(
                                      title: category.categoryName.toString(),
                                      fontSize: 12,
                                      fontFamily: FontFamily.medium,
                                      maxLine: 2,
                                      textAlign: TextAlign.center,
                                      color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.78),
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 52, width: 52, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10))),
              spaceH(height: 8),
              Container(height: 12, width: 60, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ),
    );
  }
}
