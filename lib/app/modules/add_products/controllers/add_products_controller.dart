import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/dependency/geoflutterfire/src/geoflutterfire.dart';
import 'package:eSellify/app/dependency/geoflutterfire/src/models/point.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/currency_model.dart';
import 'package:eSellify/app/models/custom_field_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/models/positions_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/app/modules/subscriptions/views/subscriptions_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddProductsController extends GetxController {
  // ─── Step 1 fields ───────────────────────────────────────
  final TextEditingController adTitleController = TextEditingController();
  final TextEditingController adDescriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // Job Category salary range (used instead of price when isJobCategory == true)
  final TextEditingController minSalaryController = TextEditingController();
  final TextEditingController maxSalaryController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  Rx<String?> countryCode = Constant.countryCode.obs;

  // Location coordinates (set when user picks from map)
  Rx<double?> selectedLatitude = Rx<double?>(null);
  Rx<double?> selectedLongitude = Rx<double?>(null);

  // Images
  final ImagePicker imagePicker = ImagePicker();
  Rx<File?> mainImage = Rx<File?>(null);
  RxList<String> otherImages = <String>[].obs;

  // Category (passed via Get.arguments)
  // categoryPath holds the full N-level chain from root → leaf
  Rx<CategoryModel> categoryModel = CategoryModel().obs;
  RxList<CategoryModel> categoryPath = <CategoryModel>[].obs;

  // Currency
  RxList<CurrencyModel> currencyList = <CurrencyModel>[].obs;
  Rx<CurrencyModel?> selectedCurrency = Rx<CurrencyModel?>(null);
  RxBool isCurrencyLoading = false.obs;

  // ─── Step 2 fields ───────────────────────────────────────
  RxList<CustomFieldModel> customFields = <CustomFieldModel>[].obs;
  RxMap<String, String> selectedRadioValues = <String, String>{}.obs;
  RxMap<String, TextEditingController> textControllers = <String, TextEditingController>{}.obs;
  RxMap<String, String> selectedDropdownValues = <String, String>{}.obs;

  // Checkboxes: fieldId → list of selected options
  RxMap<String, List<String>> selectedCheckboxValues = <String, List<String>>{}.obs;

  // File Input: fieldId → picked File
  RxMap<String, File?> selectedFileValues = <String, File?>{}.obs;

  // ─── Edit mode ───────────────────────────────────────────
  RxBool isEditing = false.obs;
  Rx<AdModel?> editingAd = Rx<AdModel?>(null);
  RxString existingMainImageUrl = ''.obs;

  // ─── Submit state ────────────────────────────────────────
  RxBool isSubmitting = false.obs;

  // ─── Featured Ads (Boost Your Ad) ────────────────────────
  // Tireda Custom: "Boost Your Ad" card support (Create/Edit Ad screen).
  // wantsFeatured is the toggle's current value. featuredSubscription holds
  // the user's active 'featured_ads' subscription (null if none / on error /
  // when freeAdFeaturing admin override is on). isCheckingFeaturedSub drives
  // the card's loading skeleton while the subscription lookup is in flight.
  RxBool wantsFeatured = false.obs;
  Rx<UserSubscriptionModel?> featuredSubscription = Rx<UserSubscriptionModel?>(null);
  RxBool isCheckingFeaturedSub = true.obs;

  // ─── Price Negotiable ─────────────────────────────────────
  // Tireda Custom: "Price Negotiable" toggle. Purely a boolean flag saved
  // alongside the ad — no extra Firestore reads/writes beyond the normal
  // saveAd/updateAd call. Hidden in the UI (and force-false at save time) for
  // job categories and price-optional categories, since those categories
  // don't carry a fixed price for this to modify.
  RxBool isNegotiable = false.obs;

  // ─── Lifecycle ───────────────────────────────────────────
  @override
  void onInit() {
    // Tireda Custom (Bug 1 fix): onInit can't itself be async, so the previous
    // version fired getArguments() and loadCurrencies() unawaited and in
    // parallel. loadCurrencies() read isEditing.value to decide which currency
    // to select, but nothing guaranteed getArguments() had already flipped
    // isEditing to true by the time it ran — a real race that could silently
    // select the wrong currency on the edit flow.
    //
    // Fix: delegate to a private async _init() that awaits getArguments() and
    // _fetchCurrencyList() together via Future.wait (same two Firestore calls,
    // same concurrency, no added reads/load-time cost — see chat), then only
    // decides the selected currency once both are guaranteed to have finished
    // and isEditing is settled.
    _init();
    super.onInit();
  }

  Future<void> _init() async {
    _prefillPhone();
    await Future.wait([
      getArguments(),
      _fetchCurrencyList(),
      _checkFeaturedSubscription(),
    ]);
    _resolveSelectedCurrency();
  }

  void _prefillPhone() {
    if (Constant.userModel?.phoneNumber != null) {
      mobileController.text = Constant.userModel!.phoneNumber!;
      countryCode.value = Constant.userModel?.countryCode ?? Constant.countryCode;
    }
  }

  // Tireda Custom: Boost Your Ad — checks whether the user has an active
  // 'featured_ads' subscription so the toggle can be gated correctly.
  // Fail-safe: FireStoreUtils.getActiveSubscription() never throws internally
  // (it logs and returns null on error), but this is still wrapped defensively
  // in case uid is null or something upstream changes. Any failure here just
  // leaves featuredSubscription null, which means the toggle-on path will
  // correctly fall through to the "no active plan" branch instead of crashing
  // or silently allowing featuring.
  Future<void> _checkFeaturedSubscription() async {
    isCheckingFeaturedSub.value = true;
    try {
      if (Constant.freeAdFeaturing) {
        // Free featuring enabled admin-side — no subscription needed, toggle
        // will always be allowed. Leave featuredSubscription null; it's not
        // consulted when freeAdFeaturing is true (see onToggleFeatured /
        // _applyFeaturedToggle).
        return;
      }
      final uid = FireStoreUtils.getCurrentUid();
      if (uid == null) {
        featuredSubscription.value = null;
        return;
      }
      featuredSubscription.value = await FireStoreUtils.getActiveSubscription(uid, 'featured_ads');
    } catch (e) {
      log('_checkFeaturedSubscription error: $e');
      featuredSubscription.value = null;
    } finally {
      isCheckingFeaturedSub.value = false;
    }
  }

  // Tireda Custom: Boost Your Ad toggle handler. Turning ON requires either
  // freeAdFeaturing (admin override) or an active 'featured_ads' subscription.
  // Turning OFF is always allowed with no checks and no network calls.
  void onToggleFeatured(bool value) {
    if (!value) {
      wantsFeatured.value = false;
      return;
    }

    final hasActivePlan = Constant.freeAdFeaturing || (featuredSubscription.value?.isActive ?? false);

    if (!hasActivePlan) {
      wantsFeatured.value = false; // keep toggle off
      ShowToastDialog.showWarning("You need to subscribe to a featured ad listing.".tr);
      Get.to(() => const SubscriptionsView());
      return;
    }

    wantsFeatured.value = true;
  }

  Future<void> getArguments() async {
    // Tireda Custom (Bug 2 fix): the whole method previously ran unawaited
    // inside onInit, so any thrown error (bad arguments shape, a null
    // 'category' in add mode, a loadCustomFields() failure) became an
    // unhandled async exception with no user-facing feedback and left the
    // screen half-initialized. Now that _init() awaits this method, wrap the
    // body in try/catch so any failure surfaces a toast instead of crashing
    // silently.
    try {
      dynamic arguments = Get.arguments;
      if (arguments == null) return;

      // ─── Edit mode ──────────────────────────────────────────
      if (arguments is Map && arguments['isEdit'] == true && arguments['ad'] != null) {
        isEditing.value = true;
        final AdModel ad = arguments['ad'];
        editingAd.value = ad;

        // Prefill form fields
        adTitleController.text = ad.title ?? '';
        adDescriptionController.text = ad.description ?? '';
        priceController.text = ad.price != null ? ad.price.toString() : '';
        minSalaryController.text = ad.minSalary != null ? ad.minSalary.toString() : '';
        maxSalaryController.text = ad.maxSalary != null ? ad.maxSalary.toString() : '';
        mobileController.text = ad.phoneNumber ?? '';
        countryCode.value = ad.countryCode ?? Constant.countryCode;
        locationController.text = ad.address ?? '';
        selectedLatitude.value = ad.location?.latitude;
        selectedLongitude.value = ad.location?.longitude;

        // Tireda Custom: prefill Boost toggle from existing ad's featured state
        wantsFeatured.value = ad.isFeatured ?? false;

        // Tireda Custom: prefill Negotiable toggle from existing ad
        isNegotiable.value = ad.isNegotiable ?? false;

        // Images
        existingMainImageUrl.value = ad.mainImage ?? '';
        if (ad.otherImages != null && ad.otherImages!.isNotEmpty) {
          otherImages.value = List<String>.from(ad.otherImages!);
        }

        // Currency
        if (ad.currency != null) {
          selectedCurrency.value = ad.currency;
        }

        // Category path (rebuild from stored paths)
        if (ad.categoryPath != null && ad.categoryNamePath != null) {
          final List<CategoryModel> rebuiltPath = [];
          for (int i = 0; i < ad.categoryPath!.length; i++) {
            rebuiltPath.add(CategoryModel(id: ad.categoryPath![i], categoryName: i < ad.categoryNamePath!.length ? ad.categoryNamePath![i] : ''));
          }
          categoryPath.value = rebuiltPath;
          if (rebuiltPath.isNotEmpty) {
            categoryModel.value = rebuiltPath.last;
          }
        }

        // Load custom fields for the leaf category
        if (ad.categoryPath != null && ad.categoryPath!.isNotEmpty) {
          final leafId = ad.categoryPath!.last;
          final parentId = ad.categoryPath!.length >= 2 ? ad.categoryPath![ad.categoryPath!.length - 2] : '';
          await loadCustomFields(leafId, parentId);
        }

        // Restore custom field values from stored list
        if (ad.customFields != null) {
          for (var fieldMap in ad.customFields!) {
            final name = fieldMap['name']?.toString() ?? '';
            final value = fieldMap['value']?.toString() ?? '';
            if (value.isEmpty) continue;

            for (var field in customFields) {
              if (field.name == name && field.id != null) {
                switch (field.type) {
                  case "Radio":
                    if (field.options != null && field.options!.contains(value)) {
                      selectedRadioValues[field.id!] = value;
                    }
                    break;
                  case "Text Input":
                  case "Number Input":
                    textControllers[field.id!] = TextEditingController(text: value);
                    break;
                  case "Dropdown":
                    if (field.options != null && field.options!.contains(value)) {
                      selectedDropdownValues[field.id!] = value;
                    }
                    break;
                  case "Checkboxes":
                    selectedCheckboxValues[field.id!] = value.split(', ').where((s) => s.isNotEmpty).toList();
                    break;
                }
                break;
              }
            }
          }
        }
        return;
      }

      // ─── Add mode (existing flow) ───────────────────────────
      // Tireda Custom (Bug 3 fix): arguments['category'] was assigned straight
      // into a non-nullable Rx<CategoryModel> with no null check. If a caller
      // ever navigated here without a category (or with a malformed arguments
      // map), this threw "Null is not a subtype of CategoryModel" with no
      // recovery. Guard it and bail out with a toast instead.
      final category = arguments is Map ? arguments['category'] : null;
      if (category == null || category is! CategoryModel) {
        ShowToastDialog.showError("Something went wrong loading this category. Please go back and try again.".tr);
        return;
      }
      categoryModel.value = category;

      final List<CategoryModel>? path = arguments['categoryPath'];
      if (path != null && path.isNotEmpty) {
        categoryPath.value = path;
      } else {
        categoryPath.value = [categoryModel.value];
      }

      await loadCustomFields(categoryModel.value.id.toString(), categoryModel.value.parentCategoryId.toString());
    } catch (e) {
      // Tireda Custom (Bug 2 fix): surface any unexpected failure in argument
      // handling / initial custom-field load instead of letting it die as an
      // unhandled exception.
      log('getArguments error: $e');
      ShowToastDialog.showError("Something went wrong loading this screen. Please go back and try again.".tr);
    }
  }

  // Tireda Custom (Bug 1 fix): split out of the old loadCurrencies() — this
  // half only fetches and stores the currency list. It makes no decision
  // about which currency to select, so it no longer needs to know whether
  // isEditing has been set yet. Same single Firestore call as before.
  Future<void> _fetchCurrencyList() async {
    isCurrencyLoading.value = true;
    try {
      final list = await FireStoreUtils().getAllCurrencies();
      currencyList.value = list;
    } catch (e) {
      log('Error loading currencies: $e');
    } finally {
      isCurrencyLoading.value = false;
    }
  }

  // Tireda Custom (Bug 1 fix): split out of the old loadCurrencies() — this
  // half is pure in-memory decision logic (no Firestore calls), so it's safe
  // to run only once both getArguments() and _fetchCurrencyList() have
  // finished. This is what removes the race: isEditing.value and
  // editingAd.value are now guaranteed final by the time this runs.
  void _resolveSelectedCurrency() {
    if (isEditing.value && editingAd.value?.currency != null) {
      // Match existing ad's currency in loaded list so dropdown works
      final adCurrencyId = editingAd.value!.currency!.id;
      final match = currencyList.firstWhereOrNull((c) => c.id == adCurrencyId);
      selectedCurrency.value = match ?? editingAd.value!.currency;
    } else {
      // Use default currency from settings, fallback to first in list
      final defaultId = Constant.currencyModel?.id;
      final match = defaultId != null ? currencyList.firstWhereOrNull((c) => c.id == defaultId) : null;
      selectedCurrency.value = match ?? (currencyList.isNotEmpty ? currencyList.first : null);
    }
  }

  Future<void> loadCustomFields(String categoryId, String parentId) async {
    // Tireda Custom (Bug 4 fix): FireStoreUtils.getCustomFields() has no
    // try/catch of its own (unlike its sibling category methods), and this
    // call previously ran unguarded inside the unawaited getArguments(),
    // meaning any Firestore failure here (bad permissions, network drop)
    // became a silent unhandled exception. Now caught locally so a failure
    // just leaves customFields empty instead of crashing the init sequence.
    try {
      final data = await FireStoreUtils.getCustomFields(categoryId: categoryId, parentCategoryId: parentId);
      customFields.value = data;
    } catch (e) {
      log('loadCustomFields error: $e');
    }
  }

  // Called from the view after geocoding resolves
  void setLocation({required String address, required double latitude, required double longitude}) {
    locationController.text = address;
    selectedLatitude.value = latitude;
    selectedLongitude.value = longitude;
  }

  // ─── Validation ──────────────────────────────────────────

  bool validateStep1() {
    if (adTitleController.text.trim().isEmpty) {
      ShowToastDialog.showError("Ad title is required.".tr);
      return false;
    }
    if (adDescriptionController.text.trim().isEmpty) {
      ShowToastDialog.showError("Ad description is required.".tr);
      return false;
    }
    final isJobCategory = categoryModel.value.isJobCategory ?? false;
    if (isJobCategory) {
      // Job Category: salary range replaces price and is required.
      final minText = minSalaryController.text.replaceAll(',', '').trim(); //Tireda Custom Comma Separator
      final maxText = maxSalaryController.text.replaceAll(',', '').trim();
      final minVal = double.tryParse(minText);
      final maxVal = double.tryParse(maxText);
      if (minText.isEmpty || minVal == null) {
        ShowToastDialog.showError("Please enter a valid minimum salary.".tr);
        return false;
      }
      if (maxText.isEmpty || maxVal == null) {
        ShowToastDialog.showError("Please enter a valid maximum salary.".tr);
        return false;
      }
      if (maxVal < minVal) {
        ShowToastDialog.showError("Maximum salary cannot be less than minimum salary.".tr);
        return false;
      }
    } else {
      final isPriceOptional = categoryModel.value.priceOptional ?? false;
      if (!isPriceOptional) {
        final priceText = priceController.text.replaceAll(',', '').trim();
        if (priceText.isEmpty || double.tryParse(priceText) == null) {
          ShowToastDialog.showError("Please enter a valid price.".tr);
          return false;
        }
      }
    }
    if (mobileController.text.trim().isEmpty) {
      ShowToastDialog.showError("Mobile number is required.".tr);
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      ShowToastDialog.showError("Please select a location.".tr);
      return false;
    }
    if (mainImage.value == null && existingMainImageUrl.value.isEmpty) {
      ShowToastDialog.showError("Please add a main picture.".tr);
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    for (final field in customFields) {
      if (field.required != true) continue;
      final id = field.id!;
      final name = field.name ?? id;

      switch (field.type) {
        case "Radio":
          if (!selectedRadioValues.containsKey(id)) {
            ShowToastDialog.showError("please_select_value_for".trParams({"field": name}));
            return false;
          }
          break;
        case "Text Input":
          final ctrl = textControllers[id];
          if (ctrl == null || ctrl.text.trim().isEmpty) {
            ShowToastDialog.showError("please_fill_field".trParams({"field": name}));
            return false;
          }
          break;
        case "Number Input":
          final ctrl = textControllers[id];
          if (ctrl == null || ctrl.text.trim().isEmpty) {
            ShowToastDialog.showError("please_enter_number_for".trParams({"field": name}));
            return false;
          }
          final num = double.tryParse(ctrl.text.replaceAll(',', '').trim());
          if (num == null) {
            ShowToastDialog.showError("must_be_valid_number".trParams({"field": name}));
            return false;
          }
          if (field.min != null && num < field.min!) {
            ShowToastDialog.showError("minimum_number_validation".trParams({"field": name, "value": field.min.toString()}));
            return false;
          }
          if (field.max != null && num > field.max!) {
            ShowToastDialog.showError("maximum_number_validation".trParams({"field": name, "value": field.max.toString()}));
            return false;
          }
          break;
        case "Dropdown":
          if (!selectedDropdownValues.containsKey(id)) {
            ShowToastDialog.showError("please_select_value_for".trParams({"field": name}));
            return false;
          }
          break;
        case "Checkboxes":
          final selected = selectedCheckboxValues[id] ?? [];
          if (selected.isEmpty) {
            ShowToastDialog.showError("please_select_one_option".trParams({"field": name}));
            return false;
          }
          break;
        case "File Input":
          if (selectedFileValues[id] == null) {
            ShowToastDialog.showError("please_upload_file_for".trParams({"field": name}));
            return false;
          }
          break;
      }
    }
    return true;
  }

  // ─── Image pickers ───────────────────────────────────────

  Future<void> pickMainImage({required ImageSource source}) async {
    final XFile? image = await imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image != null) mainImage.value = File(image.path);
    Get.back();
  }

  void toggleCheckbox(String fieldId, String option) {
    final current = List<String>.from(selectedCheckboxValues[fieldId] ?? []);
    if (current.contains(option)) {
      current.remove(option);
    } else {
      current.add(option);
    }
    selectedCheckboxValues[fieldId] = current;
  }

  Future<void> pickFileForField(String fieldId) async {
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) selectedFileValues[fieldId] = File(image.path);
  }

  Future<void> pickOtherImages() async {
    final List<XFile> images = await imagePicker.pickMultiImage(
      imageQuality: 60,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (images.isEmpty) return;
    final remaining = 7 - otherImages.length;
    if (remaining <= 0) {
      ShowToastDialog.showError("Only 7 images are allowed.".tr);
      return;
    }
    for (var img in images.take(remaining)) {
      otherImages.add(img.path);
    }
  }

  // ─── AI Auto-Generation ─────────────────────────────────
  RxBool isAiGenerating = false.obs;

  /// True when admin enabled OpenAI in admin panel (key + toggle saved) AND
  /// the form is in CREATE mode (not edit). On edit, the button is hidden so
  /// users don't accidentally overwrite their existing copy.
  bool get isAiEnabled => OpenAiService.isEnabled && !isEditing.value;

  /// True if the user can actually press the AI button right now (image
  /// uploaded). Used to enable/disable the button visually.
  bool get canUseAi => isAiEnabled && mainImage.value != null;

  /// Calls OpenAI with the uploaded photo(s) and the user-typed product
  /// title (if any), then fills the form fields with the AI's suggestions.
  Future<void> generateWithAi() async {
    if (!OpenAiService.isEnabled) {
      ShowToastDialog.showError("AI auto-generation is not enabled".tr);
      return;
    }
    if (mainImage.value == null) {
      ShowToastDialog.showError("Please add at least the main photo first".tr);
      return;
    }

    isAiGenerating.value = true;
    ShowToastDialog.showLoader("Generating with AI...".tr);
    try {
      final images = <File>[mainImage.value!];
      for (final p in otherImages) {
        if (!p.startsWith('http')) images.add(File(p));
      }

      // Fetch all categories so AI can re-classify if user picked the wrong one.
      final allCategories = await FireStoreUtils.getAllCategory();
      final candidates = _buildLeafCandidates(allCategories);

      final result = await OpenAiService.generateAdFromPhotos(
        images: images,
        productName: adTitleController.text.trim().isEmpty ? null : adTitleController.text.trim(),
        category: categoryModel.value,
        customFields: customFields,
        availableCategories: candidates,
      );

      ShowToastDialog.closeLoader();
      if (result == null) {
        ShowToastDialog.showError("AI couldn't generate. Try again or check API key in admin panel.".tr);
        return;
      }

      // ── Switch category if AI picked a different one ─────────────
      bool switched = false;
      final pickedCategory = _resolveCategory(result, allCategories);
      log(
        'AI categoryId=${result.suggestedCategoryId} suggestedName=${result.suggestedCategoryName} '
            'resolved=${pickedCategory?.categoryName} (id=${pickedCategory?.id})',
      );
      if (pickedCategory != null && pickedCategory.id != categoryModel.value.id) {
        await _switchCategory(pickedCategory, allCategories);
        switched = true;
      }

      if (result.title?.isNotEmpty == true) adTitleController.text = result.title!;
      if (result.description?.isNotEmpty == true) adDescriptionController.text = result.description!;
      if (result.suggestedPrice != null && priceController.text.isEmpty) {
        priceController.text = result.suggestedPrice!.toStringAsFixed(0);
      }

      // Apply suggestions to custom fields by matching field name
      // Tireda Custom (Bug 5 fix): this switch previously matched lowercase
      // strings ('text', 'number', 'radio', 'dropdown', 'checkbox') against
      // field.type, but every field is actually stored/typed as "Text Input",
      // "Number Input", "Radio", "Dropdown", "Checkboxes", "File Input" (see
      // _validateStep2 and the view's own switch statements for the real
      // values). None of these cases ever matched, so AI suggestions never
      // populated a single custom field — silently. Fixed to use the correct
      // type strings, and cleaned up the accidental TextEditingController
      // leak that existed in the old "text"/"number" branch (it created and
      // discarded one controller before creating a second to actually store).
      result.customFieldValues.forEach((name, value) {
        final field = customFields.firstWhereOrNull((f) => (f.name ?? '').toLowerCase().trim() == name.toLowerCase().trim());
        if (field == null || field.id == null) return;
        switch (field.type) {
          case 'Text Input':
          case 'Number Input':
            final existing = textControllers[field.id!];
            if (existing != null) {
              existing.text = value;
            } else {
              textControllers[field.id!] = TextEditingController(text: value);
            }
            break;
          case 'Radio':
          case 'Dropdown':
            final match = (field.options ?? []).firstWhereOrNull((o) => o.toLowerCase() == value.toLowerCase());
            if (match != null) {
              if (field.type == 'Radio') {
                selectedRadioValues[field.id!] = match;
              } else {
                selectedDropdownValues[field.id!] = match;
              }
            }
            break;
          case 'Checkboxes':
            final picks = value.split(RegExp(r'[,;|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            final matched = (field.options ?? []).where((o) => picks.any((p) => p.toLowerCase() == o.toLowerCase())).toList();
            if (matched.isNotEmpty) selectedCheckboxValues[field.id!] = matched;
            break;
        }
      });

      ShowToastDialog.showSuccess(switched ? "category_changed".trParams({"categoryName": categoryModel.value.categoryName.toString()}) : "AI suggestions applied".tr);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Error: $e");
    } finally {
      isAiGenerating.value = false;
    }
  }

  /// Resolves the AI's category suggestion to a real local CategoryModel.
  /// Tries (in order):
  ///  1. Exact ID match (the AI returned a verbatim ID from our list).
  ///  2. Exact case-insensitive name match against categoryName.
  ///  3. Substring match where any category name contains the AI's text or
  ///     vice-versa (handles "iPhone" → "iPhones", "Phone" → "Mobile Phones").
  /// Restricts matches to leaf categories (no children) since only leaves are
  /// valid ad targets.
  CategoryModel? _resolveCategory(AiGeneratedAd result, List<CategoryModel> all) {
    final hasChild = <String>{
      for (final c in all)
        if ((c.parentCategoryId ?? '').isNotEmpty) c.parentCategoryId!,
    };
    bool isLeaf(CategoryModel c) => c.id != null && !hasChild.contains(c.id);

    // 1. Exact ID
    final id = result.suggestedCategoryId?.trim();
    if (id != null && id.isNotEmpty && id.toLowerCase() != 'null') {
      final byId = all.firstWhereOrNull((c) => c.id == id);
      if (byId != null) return byId;
    }

    // 2 + 3. Name-based match
    final name = result.suggestedCategoryName?.trim().toLowerCase();
    if (name == null || name.isEmpty) return null;

    // 2. Exact name (prefer leaf)
    final exact = all.firstWhereOrNull((c) => isLeaf(c) && (c.categoryName ?? '').toLowerCase().trim() == name);
    if (exact != null) return exact;
    final exactAny = all.firstWhereOrNull((c) => (c.categoryName ?? '').toLowerCase().trim() == name);
    if (exactAny != null) return exactAny;

    // 3. Substring match (prefer leaf, prefer longest name)
    final candidates =
    all.where((c) {
      final cn = (c.categoryName ?? '').toLowerCase().trim();
      if (cn.isEmpty) return false;
      return cn.contains(name) || name.contains(cn);
    }).toList()..sort((a, b) {
      final aLeaf = isLeaf(a) ? 1 : 0;
      final bLeaf = isLeaf(b) ? 1 : 0;
      if (aLeaf != bLeaf) return bLeaf - aLeaf; // leaves first
      return (b.categoryName?.length ?? 0) - (a.categoryName?.length ?? 0); // longer name first
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Build the list of LEAF categories (those with no children) plus their
  /// breadcrumb path for the AI prompt.
  List<AiCategoryCandidate> _buildLeafCandidates(List<CategoryModel> all) {
    final byId = {for (final c in all) c.id: c};
    final hasChild = <String>{
      for (final c in all)
        if ((c.parentCategoryId ?? '').isNotEmpty) c.parentCategoryId!,
    };
    final leaves = all.where((c) => c.id != null && !hasChild.contains(c.id)).toList();
    return leaves.map((leaf) {
      final names = <String>[];
      var cur = leaf;
      while (true) {
        names.insert(0, cur.categoryName ?? '');
        final pid = cur.parentCategoryId;
        if (pid == null || pid.isEmpty) break;
        final parent = byId[pid];
        if (parent == null) break;
        cur = parent;
      }
      return AiCategoryCandidate(id: leaf.id!, fullPath: names.join(' > '));
    }).toList();
  }

  /// Switch the form's category, rebuild [categoryPath] up the parent chain,
  /// and reload the custom fields for the new category.
  Future<void> _switchCategory(CategoryModel picked, List<CategoryModel> all) async {
    final byId = {for (final c in all) c.id: c};
    final path = <CategoryModel>[picked];
    var cur = picked;
    while ((cur.parentCategoryId ?? '').isNotEmpty) {
      final parent = byId[cur.parentCategoryId];
      if (parent == null) break;
      path.insert(0, parent);
      cur = parent;
    }
    categoryModel.value = picked;
    categoryPath.value = path;

    // Clear stale custom-field selections from the previous category
    selectedRadioValues.clear();
    selectedDropdownValues.clear();
    selectedCheckboxValues.clear();
    selectedFileValues.clear();
    for (final tc in textControllers.values) {
      tc.dispose();
    }
    textControllers.clear();

    await loadCustomFields(picked.id.toString(), picked.parentCategoryId.toString());
  }

  // ─── Submit ──────────────────────────────────────────────

  /// Calculate ad expiry date based on subscription/free listing rules
  Future<Timestamp?> _calculateExpiryDate() async {
    // Free ad listing
    if (Constant.freeAdListing) {
      if (Constant.unlimitedAdDuration) return null; // unlimited
      return Timestamp.fromDate(DateTime.now().add(Duration(days: Constant.freeAdListingDays)));
    }

    // Paid subscription
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));

    final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');
    if (activeSub == null) return Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));

    switch (activeSub.listingDurationType) {
      case 'standard':
        return Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
      case 'package':
        return activeSub.expiryDate; // expires with package
      case 'custom':
        final days = activeSub.customDuration ?? 30;
        return Timestamp.fromDate(DateTime.now().add(Duration(days: days)));
      default:
        return Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
    }
  }

  // Tireda Custom: Boost Your Ad — applies the toggle's decision after the ad
  // doc has already been successfully saved/updated. This NEVER blocks or
  // rolls back ad creation/update: the ad itself has already saved
  // successfully by the time this runs, so any failure here (network glitch,
  // limit reached, expired plan) only produces a secondary warning toast,
  // never an error that implies the ad post itself failed.
  //
  // On create: previousFeatured is always false (a brand-new ad can't already
  // be featured), so this only ever runs the "turning ON" branch, and only if
  // the user toggled it on.
  // On edit: compares against the ad's featured state before this edit so we
  // skip the whole method (and its Firestore calls) when the toggle wasn't
  // touched at all.
  // Tireda Custom (bug fix): this used to call ShowToastDialog.showWarning()
  // directly from inside here, and submitAd() would then immediately fire its
  // own showSuccess() toast right after with zero delay. Back-to-back toast
  // calls meant the success toast visually replaced the warning before most
  // users could read it (e.g. "featured limit reached" warning would flash
  // and vanish, leaving only "Ad posted successfully!"). Fixed by having this
  // method return the warning message (or null) instead of toasting itself —
  // submitAd() now decides ordering/timing so both messages are readable.
  Future<String?> _applyFeaturedToggle({
    required String adId,
    required bool editing,
    required bool previousFeatured,
  }) async {
    final wantsFeaturedNow = wantsFeatured.value;

    // No change requested on edit — skip entirely, no extra Firestore call.
    if (editing && wantsFeaturedNow == previousFeatured) return null;

    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return null;

    try {
      // ── Turning OFF ──────────────────────────────────────
      if (!wantsFeaturedNow) {
        if (editing && previousFeatured) {
          await FireStoreUtils.removeAdFeatured(adId);
        }
        return null;
      }

      // ── Turning ON ───────────────────────────────────────
      if (Constant.freeAdFeaturing) {
        final ok = await FireStoreUtils.markAdAsFeatured(adId, null);
        if (!ok) return "Ad saved, but couldn't be featured. Please try again from the ad detail page.".tr;
        return null;
      }

      final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'featured_ads');
      if (activeSub == null || !activeSub.isActive) {
        return "Ad saved, but your Featured Ads plan is no longer active.".tr;
      }

      if (activeSub.isItemLimitUnlimited != true) {
        final featuredCount = await FireStoreUtils.countUserFeaturedAds(uid);
        if (featuredCount >= (activeSub.adLimit ?? 0)) {
          return "Ad saved, but your featured ad limit ($featuredCount/${activeSub.adLimit}) has been reached.".tr;
        }
      }

      final ok = await FireStoreUtils.markAdAsFeatured(adId, activeSub.expiryDate);
      if (ok) {
        await FireStoreUtils.syncFeaturedAdsPosted(activeSub.id!, uid);
        return null;
      } else {
        return "Ad saved, but couldn't be featured. Please try again from the ad detail page.".tr;
      }
    } catch (e) {
      log('_applyFeaturedToggle error: $e');
      return "Ad saved, but couldn't be featured. Please try again from the ad detail page.".tr;
    }
  }

  Future<void> submitAd() async {
    if (!_validateStep2()) return;

    final bool editing = isEditing.value;

    if (!editing && !Constant.freeAdListing) {
      final uid = FireStoreUtils.getCurrentUid();
      if (uid != null) {
        final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');
        if (activeSub == null) {
          ShowToastDialog.showWarning("You need a subscription to post ads".tr);
          Get.to(() => const SubscriptionsView());
          return;
        }
        if (activeSub.isItemLimitUnlimited != true) {
          final activeAdCount = await FireStoreUtils.countUserActiveAds(uid);
          if (activeAdCount >= (activeSub.adLimit ?? 0)) {
            ShowToastDialog.showError("You have $activeAdCount active ads (limit: ${activeSub.adLimit}). Please upgrade your plan.".tr);
            Get.to(() => const SubscriptionsView());
            return;
          }
        }
      }
    }

    isSubmitting.value = true;
    ShowToastDialog.showLoader(editing ? "Updating your ad...".tr : "Posting your ad...".tr);

    try {
      final String adId = editing ? editingAd.value!.id! : Constant.getUuid();
      final user = Constant.userModel;

      // 1. Upload main image (or reuse existing URL in edit mode)
      String mainImageUrl;
      if (mainImage.value != null) {
        mainImageUrl = await Constant.uploadImageToFireStorage(mainImage.value!, 'ads/$adId', 'main');
      } else {
        mainImageUrl = existingMainImageUrl.value;
      }

      // 2. Upload other images (skip already-uploaded URLs)
      final List<String> otherImageUrls = [];
      for (int i = 0; i < otherImages.length; i++) {
        if (otherImages[i].startsWith('http')) {
          otherImageUrls.add(otherImages[i]);
        } else {
          final url = await Constant.uploadImageToFireStorage(File(otherImages[i]), 'ads/$adId', 'other_$i');
          otherImageUrls.add(url);
        }
      }

      // 3. Build consolidated custom fields list
      // Each item: { 'name': fieldName, 'icon': iconUrl, 'value': answer }
      // Stored at post time so names/icons survive admin edits or field deletion.
      final List<Map<String, dynamic>> customFieldsList = [];
      for (final field in customFields) {
        final id = field.id!;
        String value = '';
        switch (field.type) {
          case "Radio":
            value = selectedRadioValues[id] ?? '';
            break;
          case "Text Input":
            value = textControllers[id]?.text.trim() ?? '';
            break;
          case "Number Input":
            value = textControllers[id]?.text.replaceAll(',', '').trim() ?? '';
            break;
          case "Dropdown":
            value = selectedDropdownValues[id] ?? '';
            break;
          case "Checkboxes":
            final selected = selectedCheckboxValues[id] ?? [];
            value = selected.join(', ');
            break;
          case "File Input":
            final file = selectedFileValues[id];
            if (file != null) {
              value = await Constant.uploadImageToFireStorage(file, 'ads/$adId', 'field_$id');
            }
            break;
        }
        if (value.isEmpty) continue; // skip fields with no answer
        customFieldsList.add({'name': field.name ?? id, 'icon': field.image ?? '', 'value': value});
      }

      // 4. Build slug from title
      final String slug = adTitleController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

      // 6. Build N-level category path arrays
      final List<String> catIdPath = categoryPath.map((c) => c.id ?? '').toList();
      final List<String> catNamePath = categoryPath.map((c) => c.categoryName ?? '').toList();

      // 7. Build AdModel
      final priceText = priceController.text.replaceAll(',', '').trim();
      final isJobCategory = categoryModel.value.isJobCategory ?? false;
      // For job categories price is replaced by a salary range.
      final isPriceOptional = isJobCategory ? false : (categoryModel.value.priceOptional ?? false);
      final double? minSalary = isJobCategory ? double.tryParse(minSalaryController.text.replaceAll(',', '').trim()) : null;
      final double? maxSalary = isJobCategory ? double.tryParse(maxSalaryController.text.replaceAll(',', '').trim()) : null;

      // Tireda Custom: Negotiable only applies to normal fixed-price ads.
      // Force false for job categories and price-optional categories even if
      // isNegotiable.value was somehow left true from a prior category
      // switch, so stale state can never persist into Firestore.
      final bool isNegotiableValue = (isJobCategory || isPriceOptional) ? false : isNegotiable.value;

      GeoFirePoint geoPoint = Geoflutterfire().point(latitude: selectedLatitude.value ?? 0.0, longitude: selectedLongitude.value ?? 0.0);

      final AdModel ad = AdModel(
        id: adId,
        title: adTitleController.text.trim(),
        description: adDescriptionController.text.trim(),
        slug: slug,
        price: isJobCategory ? null : (isPriceOptional ? null : double.tryParse(priceText)),
        isPriceOptional: isPriceOptional,
        isJobCategory: isJobCategory,
        isNegotiable: isNegotiableValue,
        minSalary: minSalary,
        maxSalary: maxSalary,
        currency: selectedCurrency.value,
        categoryPath: catIdPath,
        categoryNamePath: catNamePath,
        sellerId: user?.id,
        sellerName: user?.fullNameString(),
        sellerProfile: user?.profilePic,

        // --- PRODUCTION VERIFIED SYNC LOGIC HERE ---
        isSellerVerified: user?.isVerified ?? false,
        // -------------------------------------------

        countryCode: countryCode.value,
        phoneNumber: mobileController.text.trim(),
        address: locationController.text.trim(),
        location: LocationLatLng(latitude: selectedLatitude.value, longitude: selectedLongitude.value),
        position: Positions(geoPoint: geoPoint.geoPoint, geohash: geoPoint.hash),
        mainImage: mainImageUrl,
        otherImages: otherImageUrls,
        customFields: customFieldsList,
        status: editing ? (Constant.autoApproveEditedAds ? 'active' : 'resubmitted') : (Constant.autoApproveAds ? 'active' : 'pending'),
        isActive: editing ? Constant.autoApproveEditedAds : Constant.autoApproveAds,
        views: editing ? editingAd.value!.views : 0,
        likes: editing ? editingAd.value!.likes : 0,
        createdAt: editing ? editingAd.value!.createdAt : Timestamp.now(),
        updatedAt: Timestamp.now(),
        expiryDate: editing ? editingAd.value!.expiryDate : await _calculateExpiryDate(),
        searchKeywords: Constant.generateKeywords(adTitleController.text.trim()),
      );

      // 8. Save or Update in Firestore
      final bool success;
      if (editing) {
        success = await FireStoreUtils.updateAd(ad);
      } else {
        success = await FireStoreUtils.saveAd(ad);
      }

      ShowToastDialog.closeLoader();

      if (success) {
        // Tireda Custom: Boost Your Ad — apply after successful save/update.
        // Never blocks or reverses the ad-posted success flow below; any
        // featuring failure only produces a returned warning message, shown
        // further down instead of toasting immediately here.
        final featureWarning = await _applyFeaturedToggle(
          adId: adId,
          editing: editing,
          previousFeatured: editing ? (editingAd.value?.isFeatured ?? false) : false,
        );

        // Sync ads posted count on subscription (new ads only)
        if (!editing && !Constant.freeAdListing) {
          final uid = FireStoreUtils.getCurrentUid();
          if (uid != null) {
            final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');
            if (activeSub != null) {
              await FireStoreUtils.syncAdsPosted(activeSub.id!, uid);
            }
          }
        }

        // Notify followers about the new ad (fire-and-forget; new ads only).
        if (!editing) {
          FireStoreUtils.notifyFollowersOfNewAd(
            adId: ad.id ?? '',
            adTitle: ad.title ?? '',
          );
        }

        // Tireda Custom (bug fix): if featuring produced a warning, show it
        // first and give it a couple seconds on screen before the success
        // toast (and navigation) fires. Previously these fired back-to-back
        // with no gap, so the warning was visually replaced by the success
        // toast before it could be read.
        if (featureWarning != null) {
          ShowToastDialog.showWarning(featureWarning);
          await Future.delayed(const Duration(seconds: 2));
        }

        if (editing) {
          ShowToastDialog.showSuccess("Ad updated successfully!".tr);
          Get.back(result: true); // back to detail
          Get.back(result: true); // back to my ads list
        } else {
          ShowToastDialog.showSuccess("Ad posted successfully!".tr);
          Get.offAllNamed(Routes.DASHBOARD_SCREEN);
        }
      } else {
        ShowToastDialog.showError(editing ? "Failed to update ad.".tr : "Failed to post ad. Please try again.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log('submitAd error: $e');
      ShowToastDialog.showError("Something went wrong. Please try again.".tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────
  @override
  void onClose() {
    adTitleController.dispose();
    adDescriptionController.dispose();
    priceController.dispose();
    minSalaryController.dispose();
    maxSalaryController.dispose();
    mobileController.dispose();
    locationController.dispose();
    for (final ctrl in textControllers.values) {
      ctrl.dispose();
    }
    selectedCheckboxValues.clear();
    selectedFileValues.clear();
    super.onClose();
  }
}