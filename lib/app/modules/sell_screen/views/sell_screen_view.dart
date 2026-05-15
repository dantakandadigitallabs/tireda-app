import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/modules/add_products/views/add_products_view.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/sell_screen_controller.dart';

class SellScreenView extends GetView<SellScreenController> {
  const SellScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: SellScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "What are you offering ?", isBack: false),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  controller.isLoading.value
                      ? _CategoryShimmerGrid(isDark: themeChange.isDarkTheme())
                      : controller.categoryList.isEmpty
                      ? Center(child: TextCustom(title: "No Categories Found".tr))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.categoryList.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 12, childAspectRatio: 0.75),
                          itemBuilder: (context, index) {
                            CategoryModel category = controller.categoryList[index];
                            return InkWell(
                              onTap: () async {
                                if (!await controller.canPostAd()) return;
                                final subCategories = controller.getSubCategory(category.id!);
                                if (subCategories.isEmpty) {
                                  Get.to(
                                    () => AddProductsView(),
                                    arguments: {
                                      "category": category,
                                      "categoryPath": [category],
                                    },
                                  );
                                } else {
                                  Get.to(() => SellSubCategoryScreen(parentCategory: category, parentPath: [category]));
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 52,
                                      width: 52,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2,
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
                                        color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  spaceH(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY SHIMMER GRID — skeleton loading matching the category grid layout
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryShimmerGrid extends StatelessWidget {
  final bool isDark;

  const _CategoryShimmerGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 12, childAspectRatio: 0.75),
        itemBuilder: (_, _) => Column(
          children: [
            Container(
              height: 84,
              decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(8)),
            ),
            spaceH(height: 6),
            Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}

class SellSubCategoryScreen extends StatelessWidget {
  final CategoryModel parentCategory;
  final List<CategoryModel> parentPath;

  SellSubCategoryScreen({required this.parentCategory, required this.parentPath}) : super(key: ValueKey(parentCategory.id));

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final controller = Get.find<SellScreenController>();
    final subCategories = controller.getSubCategory(parentCategory.id!);
    return Scaffold(
      backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, parentCategory.categoryName.toString()),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subCategories.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              CategoryModel category = subCategories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    final next = controller.getSubCategory(category.id!);
                    final newPath = [...parentPath, category];

                    if (next.isEmpty) {
                      Get.to(() => AddProductsView(), arguments: {"category": category, "categoryPath": newPath});
                    } else {
                      Get.to(() => SellSubCategoryScreen(parentCategory: category, parentPath: newPath), preventDuplicates: false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2, borderRadius: BorderRadius.circular(10)),
                          child: NetworkImageWidget(imageUrl: category.image.toString(), fit: BoxFit.contain),
                        ),
                        spaceW(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextCustom(
                                title: category.categoryName.toString(),
                                fontSize: 15,
                                fontFamily: FontFamily.medium,
                                color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                              ),
                              if (category.description != null && category.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: TextCustom(
                                    title: category.description!,
                                    fontSize: 12,
                                    color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6,
                                    maxLine: 1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        spaceW(width: 8),
                        Icon(Icons.chevron_right, size: 22, color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
