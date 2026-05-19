import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ─── Lifecycle ───────────────────────────────────────────
  @override
  void onInit() {
    getArguments();
    loadCurrencies();
    _prefillPhone();
    super.onInit();
  }

  void _prefillPhone() {
    if (Constant.userModel?.phoneNumber != null) {
      mobileController.text = Constant.userModel!.phoneNumber!;
      countryCode.value = Constant.userModel?.countryCode ?? Constant.countryCode;
    }
  }

  Future<void> getArguments() async {
    dynamic arguments = Get.arguments;
    if (arguments == null) return;

    // ─── Edit mode ──────────────────────────────────────────
    if (arguments['isEdit'] == true && arguments['ad'] != null) {
      isEditing.value = true;
      final AdModel ad = arguments['ad'];
      editingAd.value = ad;

      // Prefill form fields
      adTitleController.text = ad.title ?? '';
      adDescriptionController.text = ad.description ?? '';
      priceController.text = ad.price != null ? ad.price.toString() : '';
      mobileController.text = ad.phoneNumber ?? '';
      countryCode.value = ad.countryCode ?? Constant.countryCode;
      locationController.text = ad.address ?? '';
      selectedLatitude.value = ad.location?.latitude;
      selectedLongitude.value = ad.location?.longitude;

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
          rebuiltPath.add(CategoryModel(
            id: ad.categoryPath![i],
            categoryName: i < ad.categoryNamePath!.length ? ad.categoryNamePath![i] : '',
          ));
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
    categoryModel.value = arguments['category'];

    final List<CategoryModel>? path = arguments['categoryPath'];
    if (path != null && path.isNotEmpty) {
      categoryPath.value = path;
    } else {
      categoryPath.value = [categoryModel.value];
    }

    await loadCustomFields(categoryModel.value.id.toString(), categoryModel.value.parentCategoryId.toString());
  }

  Future<void> loadCurrencies() async {
    isCurrencyLoading.value = true;
    try {
      final list = await FireStoreUtils().getAllCurrencies();
      currencyList.value = list;

      if (isEditing.value && editingAd.value?.currency != null) {
        // Match existing ad's currency in loaded list so dropdown works
        final adCurrencyId = editingAd.value!.currency!.id;
        final match = list.firstWhereOrNull((c) => c.id == adCurrencyId);
        selectedCurrency.value = match ?? editingAd.value!.currency;
      } else {
        // Use default currency from settings, fallback to first in list
        final defaultId = Constant.currencyModel?.id;
        final match = defaultId != null ? list.firstWhereOrNull((c) => c.id == defaultId) : null;
        selectedCurrency.value = match ?? (list.isNotEmpty ? list.first : null);
      }
    } catch (e) {
      log('Error loading currencies: $e');
    } finally {
      isCurrencyLoading.value = false;
    }
  }

  Future<void> loadCustomFields(String categoryId, String parentId) async {
    final data = await FireStoreUtils.getCustomFields(categoryId: categoryId, parentCategoryId: parentId);
    customFields.value = data;
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
      ShowToastDialog.showError("Ad title is required.");
      return false;
    }
    if (adDescriptionController.text.trim().isEmpty) {
      ShowToastDialog.showError("Ad description is required.");
      return false;
    }
    final isPriceOptional = categoryModel.value.priceOptional ?? false;
    if (!isPriceOptional) {
      final priceText = priceController.text.trim();
      if (priceText.isEmpty || double.tryParse(priceText) == null) {
        ShowToastDialog.showError("Please enter a valid price.");
        return false;
      }
    }
    if (mobileController.text.trim().isEmpty) {
      ShowToastDialog.showError("Mobile number is required.");
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      ShowToastDialog.showError("Please select a location.");
      return false;
    }
    if (mainImage.value == null && existingMainImageUrl.value.isEmpty) {
      ShowToastDialog.showError("Please add a main picture.");
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
            ShowToastDialog.showError("Please select a value for '$name'.");
            return false;
          }
          break;
        case "Text Input":
          final ctrl = textControllers[id];
          if (ctrl == null || ctrl.text.trim().isEmpty) {
            ShowToastDialog.showError("Please fill in '$name'.");
            return false;
          }
          break;
        case "Number Input":
          final ctrl = textControllers[id];
          if (ctrl == null || ctrl.text.trim().isEmpty) {
            ShowToastDialog.showError("Please enter a number for '$name'.");
            return false;
          }
          final num = double.tryParse(ctrl.text.trim());
          if (num == null) {
            ShowToastDialog.showError("'$name' must be a valid number.");
            return false;
          }
          if (field.min != null && num < field.min!) {
            ShowToastDialog.showError("'$name' must be at least ${field.min}.");
            return false;
          }
          if (field.max != null && num > field.max!) {
            ShowToastDialog.showError("'$name' must be at most ${field.max}.");
            return false;
          }
          break;
        case "Dropdown":
          if (!selectedDropdownValues.containsKey(id)) {
            ShowToastDialog.showError("Please select a value for '$name'.");
            return false;
          }
          break;
        case "Checkboxes":
          final selected = selectedCheckboxValues[id] ?? [];
          if (selected.isEmpty) {
            ShowToastDialog.showError("Please select at least one option for '$name'.");
            return false;
          }
          break;
        case "File Input":
          if (selectedFileValues[id] == null) {
            ShowToastDialog.showError("Please upload a file for '$name'.");
            return false;
          }
          break;
      }
    }
    return true;
  }

  // ─── Image pickers ───────────────────────────────────────

  Future<void> pickMainImage({required ImageSource source}) async {
    final XFile? image = await imagePicker.pickImage(source: source, imageQuality: 80);
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
    final List<XFile> images = await imagePicker.pickMultiImage(imageQuality: 60);
    if (images.isEmpty) return;
    final remaining = 6 - otherImages.length;
    if (remaining <= 0) {
      ShowToastDialog.showError("Only 6 images are allowed.");
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
      ShowToastDialog.showError("AI auto-generation is not enabled");
      return;
    }
    if (mainImage.value == null) {
      ShowToastDialog.showError("Please add at least the main photo first");
      return;
    }

    isAiGenerating.value = true;
    ShowToastDialog.showLoader("Generating with AI...");
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
        ShowToastDialog.showError("AI couldn't generate. Try again or check API key in admin panel.");
        return;
      }

      // ── Switch category if AI picked a different one ─────────────
      bool switched = false;
      final pickedCategory = _resolveCategory(result, allCategories);
      log('AI categoryId=${result.suggestedCategoryId} suggestedName=${result.suggestedCategoryName} '
          'resolved=${pickedCategory?.categoryName} (id=${pickedCategory?.id})');
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
      result.customFieldValues.forEach((name, value) {
        final field = customFields.firstWhereOrNull(
              (f) => (f.name ?? '').toLowerCase().trim() == name.toLowerCase().trim(),
        );
        if (field == null || field.id == null) return;
        switch (field.type) {
          case 'text':
          case 'number':
            (textControllers[field.id!] ?? TextEditingController()).text = value;
            textControllers[field.id!] = textControllers[field.id!] ?? TextEditingController(text: value);
            break;
          case 'radio':
          case 'dropdown':
            final match = (field.options ?? []).firstWhereOrNull(
                  (o) => o.toLowerCase() == value.toLowerCase(),
            );
            if (match != null) {
              if (field.type == 'radio') {
                selectedRadioValues[field.id!] = match;
              } else {
                selectedDropdownValues[field.id!] = match;
              }
            }
            break;
          case 'checkbox':
            final picks = value.split(RegExp(r'[,;|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            final matched = (field.options ?? []).where((o) => picks.any((p) => p.toLowerCase() == o.toLowerCase())).toList();
            if (matched.isNotEmpty) selectedCheckboxValues[field.id!] = matched;
            break;
        }
      });

      ShowToastDialog.showSuccess(switched
          ? "Category changed to ${categoryModel.value.categoryName} based on your photo"
          : "AI suggestions applied");
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Error: $e");
    } finally {
      isAiGenerating.value = false;
    }
  }

  /// Resolves the AI's category suggestion to a real local CategoryModel.
  CategoryModel? _resolveCategory(AiGeneratedAd result, List<CategoryModel> all) {
    final hasChild = <String>{for (final c in all) if ((c.parentCategoryId ?? '').isNotEmpty) c.parentCategoryId!};
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
    final exact = all.firstWhereOrNull(
          (c) => isLeaf(c) && (c.categoryName ?? '').toLowerCase().trim() == name,
    );
    if (exact != null) return exact;
    final exactAny = all.firstWhereOrNull((c) => (c.categoryName ?? '').toLowerCase().trim() == name);
    if (exactAny != null) return exactAny;

    // 3. Substring match (prefer leaf, prefer longest name)
    final candidates = all
        .where((c) {
      final cn = (c.categoryName ?? '').toLowerCase().trim();
      if (cn.isEmpty) return false;
      return cn.contains(name) || name.contains(cn);
    })
        .toList()
      ..sort((a, b) {
        final aLeaf = isLeaf(a) ? 1 : 0;
        final bLeaf = isLeaf(b) ? 1 : 0;
        if (aLeaf != bLeaf) return bLeaf - aLeaf; // leaves first
        return (b.categoryName?.length ?? 0) - (a.categoryName?.length ?? 0); // longer name first
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  List<AiCategoryCandidate> _buildLeafCandidates(List<CategoryModel> all) {
    final byId = {for (final c in all) c.id: c};
    final hasChild = <String>{for (final c in all) if ((c.parentCategoryId ?? '').isNotEmpty) c.parentCategoryId!};
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

  Future<void> submitAd() async {
    if (!_validateStep2()) return;

    isSubmitting.value = true;
    final bool editing = isEditing.value;
    ShowToastDialog.showLoader(editing ? "Updating your ad..." : "Posting your ad...");

    try {
      final String adId = editing ? editingAd.value!.id! : Constant.getUuid();
      final user = Constant.userModel;

      // 1. Upload main image
      String mainImageUrl;
      if (mainImage.value != null) {
        mainImageUrl = await Constant.uploadImageToFireStorage(mainImage.value!, 'ads/$adId', 'main');
      } else {
        mainImageUrl = existingMainImageUrl.value;
      }

      // 2. Upload other images
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
            value = textControllers[id]?.text.trim() ?? '';
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
        customFieldsList.add({
          'name': field.name ?? id,
          'icon': field.image ?? '',
          'value': value,
        });
      }

      // 4. Build slug from title
      final String slug = adTitleController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

      // 6. Build N-level category path arrays
      final List<String> catIdPath = categoryPath.map((c) => c.id ?? '').toList();
      final List<String> catNamePath = categoryPath.map((c) => c.categoryName ?? '').toList();

      // 7. Build AdModel
      final priceText = priceController.text.trim();
      final isPriceOptional = categoryModel.value.priceOptional ?? false;

      GeoFirePoint geoPoint = Geoflutterfire().point(
        latitude: selectedLatitude.value ?? 0.0,
        longitude: selectedLongitude.value ?? 0.0,
      );

      final AdModel ad = AdModel(
        id: adId,
        title: adTitleController.text.trim(),
        description: adDescriptionController.text.trim(),
        slug: slug,
        price: isPriceOptional ? null : double.tryParse(priceText),
        isPriceOptional: isPriceOptional,
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
        status: editing
            ? (Constant.autoApproveEditedAds ? 'active' : 'resubmitted')
            : (Constant.autoApproveAds ? 'active' : 'pending'),
        isActive: editing
            ? Constant.autoApproveEditedAds
            : Constant.autoApproveAds,
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
        if (!editing && !Constant.freeAdListing) {
          final uid = FireStoreUtils.getCurrentUid();
          if (uid != null) {
            final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');
            if (activeSub != null) {
              await FireStoreUtils.syncAdsPosted(activeSub.id!, uid);
            }
          }
        }

        if (editing) {
          ShowToastDialog.showSuccess("Ad updated successfully!");
          Get.back(result: true); // back to detail
          Get.back(result: true); // back to my ads list
        } else {
          ShowToastDialog.showSuccess("Ad posted successfully!");
          Get.offAllNamed(Routes.DASHBOARD_SCREEN);
        }
      } else {
        ShowToastDialog.showError(editing ? "Failed to update ad." : "Failed to post ad. Please try again.");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      log('submitAd error: $e');
      ShowToastDialog.showError("Something went wrong. Please try again.");
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    adTitleController.dispose();
    adDescriptionController.dispose();
    priceController.dispose();
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