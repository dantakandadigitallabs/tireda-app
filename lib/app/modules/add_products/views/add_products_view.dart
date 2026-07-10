import 'dart:io';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/data/nigeria_locations.dart';
import 'package:eSellify/app/dependency/dotted_border/dotted_border.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/currency_model.dart';
import 'package:eSellify/app/models/custom_field_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_field_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/add_products_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Basic Ad Details
// ─────────────────────────────────────────────────────────────────────────────
class AddProductsView extends GetView<AddProductsController> {
  const AddProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder<AddProductsController>(
      init: AddProductsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey2,
          appBar: UiInterface.customAppBar(context, themeChange, controller.isEditing.value ? "Edit Ad" : "Post Your Ad"),
          body: Column(
            children: [
              _StepIndicator(currentStep: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Category breadcrumb ───────────────────────────
                      // Wrapped in Obx so AI category re-classification triggers a rebuild.
                      Obx(() => _CategoryBreadcrumb(path: controller.categoryPath.toList(), isDark: isDark)),
                      spaceH(height: 16),

                      // ── Images ────────────────────────────────────────
                      _SectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: "Main Picture *", isDark: isDark),
                            spaceH(height: 10),
                            _MainImagePicker(controller: controller, context: context, themeChange: themeChange, isDark: isDark),
                            spaceH(height: 20),
                            _SectionTitle(title: "Other Pictures", subtitle: "(max 6)", isDark: isDark),
                            spaceH(height: 10),
                            _OtherImagesPicker(controller: controller, themeChange: themeChange, isDark: isDark),
                          ],
                        ),
                      ),
                      spaceH(height: 12),

                      // ── Ad Title & Description ─────────────────────────
                      _SectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AI Generate button — shown whenever admin has enabled
                            // OpenAI. Disabled-look until a main photo is added so the
                            // user discovers the feature even before uploading.
                            Obx(() {
                              if (!controller.isAiEnabled) return const SizedBox.shrink();
                              final ready = controller.canUseAi;
                              final busy = controller.isAiGenerating.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: GestureDetector(
                                  onTap: busy ? null : controller.generateWithAi,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: ready
                                            ? [AppThemeData.primary4, AppThemeData.primary4.withValues(alpha: 0.7)]
                                            : [AppThemeData.primary4.withValues(alpha: 0.45), AppThemeData.primary4.withValues(alpha: 0.3)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        busy
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          busy
                                              ? "Generating..."
                                              : ready
                                              ? "Generate with AI from photos"
                                              : "Add a photo to generate with AI",
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: FontFamily.semiBold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            TextFieldWidget(title: "Ad Title *", hintText: "What are you selling?", controller: controller.adTitleController, onPress: () {}),
                            spaceH(height: 16),
                            TextFieldWidget(title: "Description *", hintText: "Describe your item...", controller: controller.adDescriptionController, line: 4, onPress: () {}),
                          ],
                        ),
                      ),
                      spaceH(height: 12),

                      // ── Price / Salary ────────────────────────────────
                      // Job categories show a Min/Max salary range instead of price.
                      Obx(() {
                        final isJobCategory = controller.categoryModel.value.isJobCategory ?? false;
                        if (isJobCategory) {
                          return _SalarySection(controller: controller, isDark: isDark);
                        }
                        final isPriceOptional = controller.categoryModel.value.priceOptional ?? false;
                        if (isPriceOptional) return const SizedBox.shrink();
                        return _SectionCard(
                          isDark: isDark,
                          child: Obx(() {
                            if (controller.isCurrencyLoading.value) {
                              return _PriceLoadingSkeleton(isDark: isDark);
                            }
                            return TextFieldWidget(
                              title: "Price *",
                              hintText: "0",
                              controller: controller.priceController,
                              onPress: () {},
                              textInputType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              prefix: controller.currencyList.isEmpty ? null : _CurrencyDropdown(controller: controller),
                            );
                          }),
                        );
                      }),
                      Obx(() {
                        final isJobCategory = controller.categoryModel.value.isJobCategory ?? false;
                        final isPriceOptional = controller.categoryModel.value.priceOptional ?? false;
                        // Hide the spacer only when the price field itself is hidden
                        // (i.e. a non-job category whose price is optional).
                        return (!isJobCategory && isPriceOptional) ? const SizedBox.shrink() : spaceH(height: 12);
                      }),

                      // ── Mobile Number ─────────────────────────────────
                      _SectionCard(
                        isDark: isDark,
                        child: Obx(
                              () => MobileNumberTextField(
                            title: "Mobile Number *",
                            controller: controller.mobileController,
                            countryCode: controller.countryCode.value.toString(),
                            onCountryCodeChanged: (code) => controller.countryCode.value = code,
                            onPress: () {},
                          ),
                        ),
                      ),
                      spaceH(height: 12),

                      // ── Location — Nigerian State / LGA Picker ────────
                      _SectionCard(
                        isDark: isDark,
                        child: TextFieldWidget(
                          title: "Location *",
                          hintText: "Select State & LGA",
                          controller: controller.locationController,
                          onPress: () async {
                            final result = await _showNigeriaLocationPicker(context, isDark);
                            if (result == null) return;
                            final address = "${result.lga.name}, ${result.state.state}";
                            controller.setLocation(
                              address: address,
                              latitude: result.lga.lat,
                              longitude: result.lga.lng,
                            );
                          },
                        ),
                      ),
                      spaceH(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Next Button ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 10),
                      child: RoundShapeButton(
                        title: "Next  →",
                        buttonColor: AppThemeData.primary4,
                        buttonTextColor: AppThemeData.primaryWhite,
                        size: Size(double.infinity, ScreenSize.height(7, context)),
                        onTap: () {
                          if (controller.validateStep1()) {
                            Get.to(() => const AddProductsViewStep2());
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NIGERIA LOCATION PICKER (reusable within this file)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationResult {
  final NigeriaLocation state;
  final NigeriaLGA lga;
  const _LocationResult({required this.state, required this.lga});
}

Future<_LocationResult?> _showNigeriaLocationPicker(
    BuildContext context,
    bool isDark,
    ) async {
  return await Navigator.of(context).push<_LocationResult>(
    MaterialPageRoute(
      builder: (_) => _NigeriaStatePicker(isDark: isDark),
    ),
  );
}

// ── Step 1: State Picker ──────────────────────────────────────────────────────
class _NigeriaStatePicker extends StatefulWidget {
  final bool isDark;
  const _NigeriaStatePicker({required this.isDark});

  @override
  State<_NigeriaStatePicker> createState() => _NigeriaStatePickerState();
}

class _NigeriaStatePickerState extends State<_NigeriaStatePicker> {
  final TextEditingController _search = TextEditingController();
  List<NigeriaLocation> _filtered = NigeriaLocations.states;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = NigeriaLocations.searchStates(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppThemeData.grey10 : AppThemeData.grey1;
    final cardBg = widget.isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    final textColor = widget.isDark ? AppThemeData.grey1 : AppThemeData.grey10;
    final subColor = widget.isDark ? AppThemeData.grey5 : AppThemeData.grey6;
    final borderColor = widget.isDark ? AppThemeData.grey8 : AppThemeData.grey3;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Select State",
          style: TextStyle(fontSize: 18, fontFamily: FontFamily.bold, color: textColor),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Find state...",
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                filled: true,
                fillColor: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) {
                final state = _filtered[i];
                return InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context).push<_LocationResult>(
                      MaterialPageRoute(
                        builder: (_) => _NigeriaLGAPicker(state: state, isDark: widget.isDark),
                      ),
                    );
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  child: Container(
                    color: cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.location_city_rounded, size: 20, color: subColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.state, style: TextStyle(fontSize: 15, fontFamily: FontFamily.medium, color: textColor)),
                              const SizedBox(height: 2),
                              Text("${state.lgas.length} LGAs", style: TextStyle(fontSize: 12, color: subColor)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: subColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: LGA Picker ────────────────────────────────────────────────────────
class _NigeriaLGAPicker extends StatefulWidget {
  final NigeriaLocation state;
  final bool isDark;
  const _NigeriaLGAPicker({required this.state, required this.isDark});

  @override
  State<_NigeriaLGAPicker> createState() => _NigeriaLGAPickerState();
}

class _NigeriaLGAPickerState extends State<_NigeriaLGAPicker> {
  final TextEditingController _search = TextEditingController();
  late List<NigeriaLGA> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.state.lgas;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = NigeriaLocations.searchLGAs(widget.state, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppThemeData.grey10 : AppThemeData.grey1;
    final cardBg = widget.isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;
    final textColor = widget.isDark ? AppThemeData.grey1 : AppThemeData.grey10;
    final subColor = widget.isDark ? AppThemeData.grey5 : AppThemeData.grey6;
    final borderColor = widget.isDark ? AppThemeData.grey8 : AppThemeData.grey3;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select LGA", style: TextStyle(fontSize: 16, fontFamily: FontFamily.bold, color: textColor)),
            Text(widget.state.state, style: TextStyle(fontSize: 12, color: AppThemeData.primary4)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Find LGA...",
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                filled: true,
                fillColor: widget.isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
              itemBuilder: (_, i) {
                final lga = _filtered[i];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(_LocationResult(state: widget.state, lga: lga)),
                  child: Container(
                    color: cardBg,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 20, color: subColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(lga.name, style: TextStyle(fontSize: 15, fontFamily: FontFamily.medium, color: textColor)),
                        ),
                        Icon(Icons.chevron_right, color: subColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Custom Fields + Submit
// ─────────────────────────────────────────────────────────────────────────────
class AddProductsViewStep2 extends GetView<AddProductsController> {
  const AddProductsViewStep2({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetX<AddProductsController>(
      init: AddProductsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey2,
          appBar: UiInterface.customAppBar(context, themeChange, controller.isEditing.value ? "Edit Ad Details" : "Ad Details"),
          body: Column(
            children: [
              _StepIndicator(currentStep: 2),
              Expanded(
                child: controller.customFields.isEmpty
                    ? _EmptyCustomFields(isDark: isDark)
                    : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextCustom(
                              title: "Tell us more about your item",
                              fontSize: 14,
                              fontFamily: FontFamily.medium,
                              color: isDark ? AppThemeData.grey3 : AppThemeData.grey7,
                            ),
                            spaceH(height: 16),
                            ...controller.customFields.map((field) {
                              switch (field.type) {
                                case "Radio":
                                  return _RadioField(field: field, controller: controller, isDark: isDark);
                                case "Text Input":
                                  return _TextInputField(field: field, controller: controller, isDark: isDark);
                                case "Number Input":
                                  return _NumberInputField(field: field, controller: controller, isDark: isDark);
                                case "Dropdown":
                                  return _DropdownField(field: field, controller: controller, context: context, isDark: isDark, themeChange: themeChange);
                                case "Checkboxes":
                                  return _CheckboxField(field: field, controller: controller, isDark: isDark);
                                case "File Input":
                                  return _FileInputField(field: field, controller: controller, isDark: isDark);
                                default:
                                  return const SizedBox.shrink();
                              }
                            }),
                          ],
                        ),
                      ),
                      spaceH(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Post Ad Button ────────────────────────────────────────
              Obx(
                    () => Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 10),
                        child: RoundShapeButton(
                          title: controller.isSubmitting.value
                              ? (controller.isEditing.value ? "Updating...".tr : "Posting...")
                              : (controller.isEditing.value ? "Update Ad" : "Post Ad"),
                          buttonColor: controller.isSubmitting.value ? AppThemeData.grey5 : AppThemeData.primary4,
                          buttonTextColor: AppThemeData.primaryWhite,
                          size: Size(double.infinity, ScreenSize.height(7, context)),
                          onTap: controller.isSubmitting.value ? () {} : () => controller.submitAd(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Container(
      color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextCustom(title: "Step $currentStep of 2", fontSize: 13, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey4 : AppThemeData.grey6),
              TextCustom(title: currentStep == 1 ? "Basic Details" : "More Details", fontSize: 13, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
            ],
          ),
          spaceH(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: currentStep / 2, backgroundColor: AppThemeData.primary1, color: AppThemeData.primary4, minHeight: 5),
          ),
        ],
      ),
    );
  }
}

/// N-level category breadcrumb:  Electronics  >  Phones  >  Samsung
class _CategoryBreadcrumb extends StatelessWidget {
  final List<CategoryModel> path;
  final bool isDark;

  const _CategoryBreadcrumb({required this.path, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppThemeData.primary4.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 14, color: AppThemeData.primary4),
          spaceW(width: 6),
          Flexible(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 0,
              children: [
                for (int i = 0; i < path.length; i++) ...[
                  TextCustom(
                    title: path[i].categoryName ?? '',
                    fontSize: 12,
                    fontFamily: i == path.length - 1 ? FontFamily.semiBold : FontFamily.regular,
                    color: i == path.length - 1 ? AppThemeData.primary4 : (isDark ? AppThemeData.grey4 : AppThemeData.grey6),
                  ),
                  if (i < path.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right, size: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey5),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;

  const _SectionTitle({required this.title, this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextCustom(title: title, fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        if (subtitle != null) ...[spaceW(width: 4), TextCustom(title: subtitle!, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)],
      ],
    );
  }
}

/// Job Category salary range — Minimum & Maximum salary fields shown in place
/// of the Price field. Both are required (validated in the controller).
class _SalarySection extends StatelessWidget {
  final AddProductsController controller;
  final bool isDark;

  const _SalarySection({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      child: Obx(() {
        if (controller.isCurrencyLoading.value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SalaryLoadingSkeleton(isDark: isDark, title: "Minimum Salary *"),
              spaceH(height: 16),
              _SalaryLoadingSkeleton(isDark: isDark, title: "Maximum Salary *"),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFieldWidget(
              title: "Minimum Salary *",
              hintText: "0",
              controller: controller.minSalaryController,
              onPress: () {},
              textInputType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              prefix: controller.currencyList.isEmpty ? null : _CurrencyDropdown(controller: controller),
            ),
            spaceH(height: 16),
            TextFieldWidget(
              title: "Maximum Salary *",
              hintText: "0",
              controller: controller.maxSalaryController,
              onPress: () {},
              textInputType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              prefix: controller.currencyList.isEmpty ? null : _CurrencyDropdown(controller: controller),
            ),
          ],
        );
      }),
    );
  }
}

class _SalaryLoadingSkeleton extends StatelessWidget {
  final bool isDark;
  final String title;

  const _SalaryLoadingSkeleton({required this.isDark, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(title: title, fontSize: 14, fontFamily: FontFamily.medium),
        spaceH(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            color: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          ),
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ],
    );
  }
}

class _PriceLoadingSkeleton extends StatelessWidget {
  final bool isDark;

  const _PriceLoadingSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(title: "Price *", fontSize: 14, fontFamily: FontFamily.medium),
        spaceH(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            color: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
          ),
          child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      ],
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final AddProductsController controller;

  const _CurrencyDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Obx(
          () => DropdownButton<CurrencyModel>(
        value: controller.selectedCurrency.value,
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, size: 18, color: AppThemeData.primary4),
        dropdownColor: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.primaryWhite,
        items: controller.currencyList.map((currency) {
          return DropdownMenuItem<CurrencyModel>(
            value: currency,
            child: Text(
              "${currency.symbol} ${currency.code}",
              style: TextStyle(fontSize: 13, fontFamily: FontFamily.medium, color: AppThemeData.primary4),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) controller.selectedCurrency.value = value;
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE PICKERS
// ─────────────────────────────────────────────────────────────────────────────

class _MainImagePicker extends StatelessWidget {
  final AddProductsController controller;
  final BuildContext context;
  final DarkThemeProvider themeChange;
  final bool isDark;

  const _MainImagePicker({required this.controller, required this.context, required this.themeChange, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(context),
      child: Obx(() {
        final file = controller.mainImage.value;
        final existingUrl = controller.existingMainImageUrl.value;
        final hasImage = file != null || existingUrl.isNotEmpty;
        return DottedBorder(
          options: RoundedRectDottedBorderOptions(
            dashPattern: const [6, 6],
            color: hasImage ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4),
            radius: const Radius.circular(12),
          ),
          child: !hasImage
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 36, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                spaceH(height: 6),
                TextCustom(title: "Tap to add main photo", fontSize: 13, color: isDark ? AppThemeData.grey4 : AppThemeData.grey7),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: file != null
                      ? Image.file(file, height: 110, width: 110, fit: BoxFit.cover)
                      : NetworkImageWidget(imageUrl: existingUrl, height: 110, width: 110, fit: BoxFit.cover),
                ),
                GestureDetector(
                  onTap: () {
                    controller.mainImage.value = null;
                    controller.existingMainImageUrl.value = '';
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showImageSourceSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextCustom(title: "Select Image Source", fontSize: 16, fontFamily: FontFamily.bold),
              spaceH(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceOption(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () => controller.pickMainImage(source: ImageSource.camera),
                  ),
                  _SourceOption(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () => controller.pickMainImage(source: ImageSource.gallery),
                  ),
                ],
              ),
              spaceH(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppThemeData.primary4.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppThemeData.primary4, size: 28),
          ),
          spaceH(height: 8),
          TextCustom(title: label, fontSize: 13, fontFamily: FontFamily.medium),
        ],
      ),
    );
  }
}

class _OtherImagesPicker extends StatelessWidget {
  final AddProductsController controller;
  final DarkThemeProvider themeChange;
  final bool isDark;

  const _OtherImagesPicker({required this.controller, required this.themeChange, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...controller.otherImages.map((path) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: path.startsWith('http')
                      ? NetworkImageWidget(imageUrl: path, width: 90, height: 90, fit: BoxFit.cover)
                      : Image.file(File(path), width: 90, height: 90, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => controller.otherImages.remove(path),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }),
          if (controller.otherImages.length < 6)
            GestureDetector(
              onTap: controller.pickOtherImages,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(dashPattern: const [6, 6], color: isDark ? AppThemeData.grey7 : AppThemeData.grey4, radius: const Radius.circular(10)),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Center(child: Icon(Icons.add, size: 28, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 CUSTOM FIELD WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCustomFields extends StatelessWidget {
  final bool isDark;

  const _EmptyCustomFields({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppThemeData.success300),
          spaceH(height: 16),
          TextCustom(title: "Looking good!", fontSize: 18, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          TextCustom(
            title: "No additional details required\nfor this category.",
            fontSize: 14,
            color: isDark ? AppThemeData.grey4 : AppThemeData.grey7,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RadioField extends StatelessWidget {
  final CustomFieldModel field;
  final AddProductsController controller;
  final bool isDark;

  const _RadioField({required this.field, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldHeader(field: field, isDark: isDark),
          spaceH(height: 10),
          Obx(() {
            final selected = controller.selectedRadioValues[field.id];
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: field.options!.map((option) {
                final isSelected = selected == option;
                return GestureDetector(
                  onTap: () => controller.selectedRadioValues[field.id!] = option,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppThemeData.primary4.withOpacity(0.1) : (isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4), width: isSelected ? 1.5 : 1),
                    ),
                    child: TextCustom(
                      title: option,
                      fontSize: 13,
                      fontFamily: isSelected ? FontFamily.semiBold : FontFamily.regular,
                      color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey2 : AppThemeData.grey8),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _TextInputField extends StatelessWidget {
  final CustomFieldModel field;
  final AddProductsController controller;
  final bool isDark;

  const _TextInputField({required this.field, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!controller.textControllers.containsKey(field.id)) {
      controller.textControllers[field.id!] = TextEditingController();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldHeader(field: field, isDark: isDark),
          spaceH(height: 10),
          CustomFieldTextField(
            hintText: "Enter ${field.name}",
            controller: controller.textControllers[field.id]!,
            onPress: () {},
            fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final CustomFieldModel field;
  final AddProductsController controller;
  final BuildContext context;
  final bool isDark;
  final DarkThemeProvider themeChange;

  const _DropdownField({required this.field, required this.controller, required this.context, required this.isDark, required this.themeChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldHeader(field: field, isDark: isDark),
          spaceH(height: 10),
          Obx(
                () => DropdownButtonFormField<String>(
              initialValue: controller.selectedDropdownValues[field.id],
              hint: Text("Select ${field.name}", style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6)),
              // Selected value text — explicit theme color so it stays readable
              // in both light and dark mode (default was washed-out grey).
              style: TextStyle(fontSize: 14, fontFamily: FontFamily.medium, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              dropdownColor: isDark ? AppThemeData.grey9 : AppThemeData.primaryWhite,
              iconEnabledColor: isDark ? AppThemeData.grey3 : AppThemeData.grey7,
              items: field.options?.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) controller.selectedDropdownValues[field.id!] = value;
              },
              decoration: Constant.DefaultInputDecoration(context, fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NUMBER INPUT FIELD — numeric keyboard + optional min/max hint
// ─────────────────────────────────────────────────────────────────────────────
class _NumberInputField extends StatelessWidget {
  final CustomFieldModel field;
  final AddProductsController controller;
  final bool isDark;

  const _NumberInputField({required this.field, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (!controller.textControllers.containsKey(field.id)) {
      controller.textControllers[field.id!] = TextEditingController();
    }

    // Build hint: e.g.  "Enter Year  (1990 – 2025)"
    String hint = "Enter ${field.name}";
    if (field.min != null && field.max != null) {
      hint += "  (${field.min} – ${field.max})";
    } else if (field.min != null) {
      hint += "  (min ${field.min})";
    } else if (field.max != null) {
      hint += "  (max ${field.max})";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldHeader(field: field, isDark: isDark),
          spaceH(height: 10),
          CustomFieldTextField(
            hintText: hint,
            controller: controller.textControllers[field.id]!,
            onPress: () {},
            fillColor: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
            textInputType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          ),
          if (field.min != null || field.max != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (field.min != null)
                    TextCustom(title: "Min: ${field.min}", fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                  if (field.min != null && field.max != null) spaceW(width: 12),
                  if (field.max != null)
                    TextCustom(title: "Max: ${field.max}", fontSize: 11, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKBOXES FIELD — multi-select chip grid (same style as Radio)
// ─────────────────────────────────────────────────────────────────────────────
class _CheckboxField extends StatelessWidget {
  final CustomFieldModel field;
  final AddProductsController controller;
  final bool isDark;

  const _CheckboxField({required this.field, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldHeader(field: field, isDark: isDark),
          spaceH(height: 10),
          Obx(() {
            final selected = controller.selectedCheckboxValues[field.id] ?? [];
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (field.options ?? []).map((option) {
                final isSelected = selected.contains(option);
                return GestureDetector(
                  onTap: () => controller.toggleCheckbox(field.id!, option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppThemeData.primary4.withOpacity(0.1) : (isDark ? AppThemeData.grey9 : AppThemeData.grey2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isSelected ? AppThemeData.primary4 : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey6 : AppThemeData.grey5)),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                        ),
                        spaceW(width: 8),
                        TextCustom(
                          title: option,
                          fontSize: 13,
                          fontFamily: isSelected ? FontFamily.semiBold : FontFamily.regular,
                          color: isSelected ? AppThemeData.primary4 : (isDark ? AppThemeData.grey2 : AppThemeData.grey8),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILE INPUT FIELD — pick image from gallery, show preview
// ─────────────────────────────────────────────────────────────────────────────
class _FileInputField extends StatelessWidget {
  final CustomFieldModel field;
  final AddProductsController controller;
  final bool isDark;

  const _FileInputField({required this.field, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldHeader(field: field, isDark: isDark),
          spaceH(height: 10),
          Obx(() {
            final file = controller.selectedFileValues[field.id];
            return GestureDetector(
              onTap: () => controller.pickFileForField(field.id!),
              child: Container(
                width: double.infinity,
                height: file != null ? 140 : 80,
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey9 : AppThemeData.grey2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: file != null ? AppThemeData.primary4 : (isDark ? AppThemeData.grey7 : AppThemeData.grey4),
                    width: file != null ? 1.5 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: file == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined, size: 28, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
                    spaceH(height: 6),
                    TextCustom(
                      title: "Tap to upload",
                      fontSize: 13,
                      color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(file, width: double.infinity, height: 140, fit: BoxFit.cover),
                    ),
                    // Change / Remove overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _FileActionButton(
                            icon: Icons.edit_outlined,
                            onTap: () => controller.pickFileForField(field.id!),
                          ),
                          spaceW(width: 8),
                          _FileActionButton(
                            icon: Icons.close,
                            onTap: () => controller.selectedFileValues[field.id!] = null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FileActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _FieldHeader extends StatelessWidget {
  final CustomFieldModel field;
  final bool isDark;

  const _FieldHeader({required this.field, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: isDark ? AppThemeData.primary7 : AppThemeData.primary1, borderRadius: BorderRadius.circular(6)),
          child: NetworkImageWidget(imageUrl: field.image.toString(), height: 18, width: 18),
        ),
        spaceW(width: 10),
        Expanded(
          child: Row(
            children: [
              TextCustom(title: field.name.toString(), fontSize: 15, fontFamily: FontFamily.semiBold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
              if (field.required == true) ...[spaceW(width: 4), TextCustom(title: "*", fontSize: 15, fontFamily: FontFamily.bold, color: AppThemeData.danger300)],
            ],
          ),
        ),
      ],
    );
  }
}