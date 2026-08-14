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
// Tireda Custom Merge (eSellify 1.5): replaces NetworkImageWidget — confirm
// this file exists in Tireda's widgets/ dir before building; if not, pull
// it in from the 1.5 tree alongside this file.
import 'package:eSellify/widgets/category_image_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/sub_category_controller.dart';

class SubCategoryView extends StatelessWidget {
  /// Preferred: pass the category directly. This survives back navigation
  /// because Flutter retains the widget (and its constructor args) in the
  /// route stack, whereas `Get.arguments` can return null on re-build after
  /// a deeper push/pop cycle.
  final CategoryModel? category;

  const SubCategoryView({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    // Resolve the category from the constructor first (stable across
    // back-navigation), falling back to legacy Get.arguments for any old
    // call site that still passes the map.
    final args = Get.arguments;
    final argCategory = (args is Map && args['category'] is CategoryModel) ? args['category'] as CategoryModel : null;
    final CategoryModel resolved = category ?? argCategory ?? CategoryModel();

    // Stable tag derived from the category id — no timestamp fallback, so
    // popping back onto this view returns the same controller instance
    // with its already-loaded subCategoryList intact.
    final tag = 'sub_${resolved.id ?? 'root'}';

    // Force a fresh controller for each category level
    final controller = Get.put(SubCategoryController(), tag: tag);

    // Hydrate the controller on first mount for this category. Idempotent:
    // re-hydration with the same category is a no-op on the controller side.
    if (resolved.id != null && controller.categoryModel.value.id != resolved.id) {
      // Schedule for post-frame so we don't mutate Rx state during build.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.hydrate(resolved));
    }

    return Obx(
          () => Scaffold(
        backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
        // Tireda Custom Merge (eSellify 1.5): localized category name.
        appBar: UiInterface.customAppBar(context, themeChange, controller.categoryModel.value.categoryNameFor(Get.locale?.languageCode)),
        body: Column(
          children: [
            const Center(child: AdBannerWidget()),
            Expanded(
              child: controller.isLoading.value
                  ? _buildShimmer(isDark)
                  : controller.hasError.value
                  ? _buildErrorState(controller, isDark)
                  : controller.subCategoryList.isEmpty
                  ? _buildNoSubCategories(controller, isDark)
                  : _buildSubCategoryList(controller, isDark),
            ),
          ],
        ),
      ),
    );
  }

  /// Tireda Custom: shown when the subcategory fetch genuinely fails (network/Firestore error),
  /// so the user gets a retry option instead of being silently redirected to ads.
  Widget _buildErrorState(SubCategoryController controller, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            spaceH(height: 12),
            TextCustom(
              title: "Something went wrong. Please try again.".tr,
              fontSize: 14,
              fontFamily: FontFamily.medium,
              color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
              textAlign: TextAlign.center,
            ),
            spaceH(height: 16),
            InkWell(
              onTap: () => controller.retry(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppThemeData.primary4, borderRadius: BorderRadius.circular(10)),
                child: TextCustom(title: "Retry".tr, fontSize: 14, fontFamily: FontFamily.semiBold, color: AppThemeData.primaryWhite),
              ),
            ),
          ],
        ),
      ),
    );
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

  // Tireda Custom: local search bar, only rendered when list is long enough to need it
  Widget _buildSearchBar(SubCategoryController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(HugeIcons.strokeRoundedSearch01, size: 20, color: AppThemeData.primary4),
            spaceW(width: 12),
            Expanded(
              child: TextField(
                controller: controller.searchTextController,
                onChanged: controller.onSearchChanged,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: FontFamily.semiBold,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                ),
                decoration: InputDecoration(
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  hintText: "Search".tr,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    fontFamily: FontFamily.semiBold,
                    color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                  ),
                ),
              ),
            ),
            if (controller.searchQuery.value.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.searchTextController.clear();
                  controller.onSearchChanged('');
                },
                child: Icon(Icons.close, size: 18, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
              ),
          ],
        ),
      ),
    );
  }

  // Tireda Custom: "View all {CategoryName}" — jumps straight to ads under this category,
  // irrespective of which subcategory/brand they belong to.
  // Tireda Custom Merge (eSellify 1.5): localized category name in label.
  Widget _buildViewAllButton(SubCategoryController controller, bool isDark) {
    final cat = controller.categoryModel.value;
    final name = cat.categoryNameFor(Get.locale?.languageCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: InkWell(
        onTap: () {
          if (cat.id == null || cat.id!.isEmpty) return;
          Get.to(() => const AdsListingView(), arguments: {"categoryId": cat.id, "categoryName": cat.categoryName});
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppThemeData.primary4, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(HugeIcons.strokeRoundedGridView, size: 20, color: AppThemeData.primary4),
              spaceW(width: 10),
              Expanded(
                child: TextCustom(
                  title: "View all $name".tr,
                  fontSize: 14,
                  fontFamily: FontFamily.semiBold,
                  color: AppThemeData.primary4,
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: AppThemeData.primary4),
            ],
          ),
        ),
      ),
    );
  }

  /// Subcategories in a list view
  Widget _buildSubCategoryList(SubCategoryController controller, bool isDark) {
    return Column(
      children: [
        if (controller.shouldShowSearch) _buildSearchBar(controller, isDark),
        _buildViewAllButton(controller, isDark),
        Expanded(
          child: controller.filteredList.isEmpty
              ? Center(
            child: TextCustom(
              title: "No results found".tr,
              fontSize: 14,
              color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: controller.filteredList.length,
            itemBuilder: (context, index) {
              CategoryModel subCategory = controller.filteredList[index];
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
                          // Tireda Custom Merge (eSellify 1.5): CategoryImageWidget
                          // replaces NetworkImageWidget (adds fallback icon).
                          child: CategoryImageWidget(imageUrl: subCategory.image.toString(), isDark: isDark, radius: 6, fallbackIconSize: 20),
                        ),
                        spaceW(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tireda Custom Merge (eSellify 1.5): localized name.
                              TextCustom(
                                title: subCategory.categoryNameFor(Get.locale?.languageCode),
                                fontSize: 14,
                                fontFamily: FontFamily.medium,
                                color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                              ),
                              if (subCategory.description != null && subCategory.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  // Tireda Custom Merge (eSellify 1.5): localized description.
                                  child: TextCustom(title: subCategory.descriptionFor(Get.locale?.languageCode), fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
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
    );
  }

  /// N-level navigation: check if category has children → drill deeper, else → show ads
  Future<void> _onCategoryTap(SubCategoryController controller, CategoryModel category) async {
    // Tireda Custom: guard against a null/empty id before hitting Firestore
    // (1.5 base dropped this and calls category.id! directly — kept here
    // since AdModel-adjacent category docs can arrive without an id in
    // some edge flows).
    if (category.id == null || category.id!.isEmpty) {
      ShowToastDialog.showError("This category is unavailable right now.".tr);
      return;
    }
    ShowToastDialog.showLoader("Loading...".tr);
    final hasChildren = await controller.hasChildren(category.id!);
    ShowToastDialog.closeLoader();

    if (hasChildren) {
      // Has subcategories → navigate to SubCategoryView again (N-level).
      // Pass via constructor so the next level's view survives back-nav.
      Get.to(() => SubCategoryView(category: category), preventDuplicates: false);
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