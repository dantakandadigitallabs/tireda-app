import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/modules/add_products/views/add_products_view.dart';
import 'package:eSellify/app/dependency/shimmer.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/category_image_widget.dart';
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
          appBar: UiInterface.customAppBar(context, themeChange, "What are you offering ?".tr, isBack: false),
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
                                // Tireda Custom Merge (eSellify 1.5): CategoryImageWidget replaces NetworkImageWidget.
                                child: CategoryImageWidget(imageUrl: category.image.toString(), isDark: themeChange.isDarkTheme(), radius: 6, fallbackIconSize: 20),
                              ),
                              spaceH(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: TextCustom(
                                  // Tireda Custom Merge (eSellify 1.5): localized name.
                                  title: category.categoryNameFor(Get.locale?.languageCode),
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

// ─────────────────────────────────────────────────────────────────────────────
// SELL SUB CATEGORY SCREEN — Tireda Custom: converted to StatefulWidget to hold
// local search state (eSellify 1.5 reverted this to a plain StatelessWidget
// with no search — intentionally NOT taken). List is already sorted
// alphabetically (locale-aware) by SellScreenController.getSubCategory().
// Search bar only shown when the list is long enough to need it (>10 items),
// matching the browsing subcategory UX.
// ─────────────────────────────────────────────────────────────────────────────
class SellSubCategoryScreen extends StatefulWidget {
  final CategoryModel parentCategory;
  final List<CategoryModel> parentPath;

  SellSubCategoryScreen({required this.parentCategory, required this.parentPath}) : super(key: ValueKey(parentCategory.id));

  @override
  State<SellSubCategoryScreen> createState() => _SellSubCategoryScreenState();
}

class _SellSubCategoryScreenState extends State<SellSubCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();
    final controller = Get.find<SellScreenController>();
    final allSubCategories = controller.getSubCategory(widget.parentCategory.id!);

    // Tireda Custom Merge (eSellify 1.5): filter on the locale-resolved
    // display name, matching what's actually shown in the list below.
    final subCategories = _query.trim().isEmpty
        ? allSubCategories
        : allSubCategories.where((c) => c.categoryNameFor(Get.locale?.languageCode).toLowerCase().contains(_query.toLowerCase())).toList();

    final shouldShowSearch = allSubCategories.length > 10;

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      // Tireda Custom Merge (eSellify 1.5): localized name.
      appBar: UiInterface.customAppBar(context, themeChange, widget.parentCategory.categoryNameFor(Get.locale?.languageCode)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shouldShowSearch) ...[
              _buildSearchBar(isDark),
              spaceH(height: 12),
            ],
            Expanded(
              child: subCategories.isEmpty
                  ? Center(
                child: TextCustom(
                  title: _query.trim().isEmpty ? "No Subcategories Found".tr : "No results found".tr,
                  color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                ),
              )
                  : ListView.builder(
                itemCount: subCategories.length,
                itemBuilder: (context, index) {
                  CategoryModel category = subCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        final next = controller.getSubCategory(category.id!);
                        final newPath = [...widget.parentPath, category];

                        if (next.isEmpty) {
                          Get.to(() => AddProductsView(), arguments: {"category": category, "categoryPath": newPath});
                        } else {
                          Get.to(() => SellSubCategoryScreen(parentCategory: category, parentPath: newPath), preventDuplicates: false);
                        }
                      },
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
                              // Tireda Custom Merge (eSellify 1.5): CategoryImageWidget replaces NetworkImageWidget.
                              child: CategoryImageWidget(imageUrl: category.image.toString(), isDark: isDark, radius: 6, fallbackIconSize: 20),
                            ),
                            spaceW(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextCustom(
                                    // Tireda Custom Merge (eSellify 1.5): localized name.
                                    title: category.categoryNameFor(Get.locale?.languageCode),
                                    fontSize: 15,
                                    fontFamily: FontFamily.medium,
                                    color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                                  ),
                                  if (category.description != null && category.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: TextCustom(
                                        // Tireda Custom Merge (eSellify 1.5): localized description.
                                        title: category.descriptionFor(Get.locale?.languageCode),
                                        fontSize: 12,
                                        color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                                        maxLine: 1,
                                      ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tireda Custom: local search bar — same visual style as the browsing subcategory screen
  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 22, color: AppThemeData.primary4),
          spaceW(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontSize: 14,
                fontFamily: FontFamily.semiBold,
                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
              ),
              decoration: InputDecoration(
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                hintText: "Search".tr,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontFamily: FontFamily.semiBold,
                  color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: Icon(Icons.close, size: 18, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            ),
        ],
      ),
    );
  }
}