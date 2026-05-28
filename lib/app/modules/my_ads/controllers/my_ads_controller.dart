import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/ad_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAdsController extends GetxController {
  // ─── Raw stream list ─────────────────────────────────────
  RxList<AdModel> adList = <AdModel>[].obs;
  RxBool isLoading = true.obs;
  RxBool featuredOnly = false.obs;

  // ─── Filter & Search state ───────────────────────────────
  RxString selectedStatus = 'all'.obs;
  RxString selectedSort = 'newest'.obs;

  final TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;

  StreamSubscription<List<AdModel>>? _adSubscription;

  // ─── Filtered + sorted list ──────────────────────────────
  List<AdModel> get filteredList {
    List<AdModel> result = List.from(adList);

    // Featured filter
    if (featuredOnly.value) {
      result = result.where((ad) => ad.isFeatured == true).toList();
    }

    // Filter by status
    if (selectedStatus.value != 'all') {
      result = result.where((ad) {
        final s = (ad.status ?? '').toLowerCase();
        switch (selectedStatus.value) {
          case 'approved':
            return s == 'active' || s == 'approved';
          case 'under_review':
            return s == 'pending' || s == 'under_review';
          case 'sold_out':
            return s == 'sold' || s == 'sold_out';
          case 'expired':
            return s == 'expired';
          case 'inactive':
            return s == 'inactive';
          case 'soft_rejected':
            return s == 'soft_rejected';
          case 'permanent_rejected':
            return s == 'permanent_rejected';
          case 'resubmitted':
            return s == 'resubmitted';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.trim().toLowerCase();
      result = result.where((ad) => (ad.title ?? '').toLowerCase().contains(query)).toList();
    }

    // Sort
    switch (selectedSort.value) {
      case 'oldest':
        result.sort((a, b) => (a.createdAt?.seconds ?? 0).compareTo(b.createdAt?.seconds ?? 0));
        break;
      case 'price_high':
        result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'price_low':
        result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      default: // newest
        result.sort((a, b) => (b.createdAt?.seconds ?? 0).compareTo(a.createdAt?.seconds ?? 0));
    }

    return result;
  }

  // ─── All filter status options ───────────────────────────
  static const List<Map<String, String>> statusFilters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'approved', 'label': 'Approved'},
    {'key': 'under_review', 'label': 'Under Review'},
    {'key': 'sold_out', 'label': 'Sold Out'},
    {'key': 'expired', 'label': 'Expired'},
    {'key': 'inactive', 'label': 'Inactive'},
    {'key': 'soft_rejected', 'label': 'Soft Rejected'},
    {'key': 'permanent_rejected', 'label': 'Permanent Rejected'},
    {'key': 'resubmitted', 'label': 'Resubmitted'},
  ];

  static const List<Map<String, String>> sortOptions = [
    {'key': 'newest', 'label': 'Newest First'},
    {'key': 'oldest', 'label': 'Oldest First'},
    {'key': 'price_high', 'label': 'Price: High to Low'},
    {'key': 'price_low', 'label': 'Price: Low to High'},
  ];

  // ─── Lifecycle ───────────────────────────────────────────
  @override
  void onInit() {
    final args = Get.arguments;
    if (args != null && args['featured'] == true) {
      featuredOnly.value = true;
    }
    _listenToMyAds();
    super.onInit();
  }

  void _listenToMyAds() {
    final uid = Constant.userModel?.id;
    if (uid == null || uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _adSubscription = FireStoreUtils.getMyAdsStream(uid).listen(
          (list) {
        adList.value = list;
        isLoading.value = false;
      },
      onError: (e) {
        log('MyAdsController stream error: $e');
        isLoading.value = false;
      },
    );
  }

  // ─── Setters ─────────────────────────────────────────────
  void setStatusFilter(String status) => selectedStatus.value = status;

  void setSortOption(String sort) => selectedSort.value = sort;

  void setSearchQuery(String val) => searchQuery.value = val;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  String get activeStatusLabel {
    final match = statusFilters.firstWhere((f) => f['key'] == selectedStatus.value, orElse: () => {'label': 'Ads'});
    return match['label'] ?? 'Ads';
  }

  String get activeSortLabel {
    final match = sortOptions.firstWhere((f) => f['key'] == selectedSort.value, orElse: () => {'label': 'Newest'});
    return match['label'] ?? 'Newest';
  }

  // ─── Delete ──────────────────────────────────────────────
  Future<void> deleteAd(AdModel ad, BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (ctx, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: isDark ? const Color(0xff1A1A1A) : Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Color(0xffFFE5E7), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xffE7000B), size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Delete Ad?".tr,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "delete_ad_warning".trParams({"title": ad.title ?? "Untitled"}),

                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black45, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            child: Center(
                              child: Text(
                                "Cancel".tr,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xffE7000B)),
                            child: Center(
                              child: Text(
                                "Delete".tr,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirm != true) return;

    ShowToastDialog.showLoader("Deleting ad...".tr);
    final success = await FireStoreUtils.deleteAd(ad.id!);
    ShowToastDialog.closeLoader();

    if (success) {
      ShowToastDialog.showSuccess("Ad deleted successfully!".tr);
    } else {
      ShowToastDialog.showError("Failed to delete. Please try again.".tr);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────
  String formatPrice(AdModel ad) {
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";
    final currency = ad.currency;
    final symbol = currency?.symbol ?? '';
    final decimals = currency?.decimalDigits ?? 0;
    final price = ad.price!.toStringAsFixed(decimals);
    if (currency?.symbolAtRight == true) return "$price $symbol".trim();
    return "$symbol$price".trim();
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} , ${dt.year}";
  }

  String statusLabel(AdModel ad) {
    switch ((ad.status ?? '').toLowerCase()) {
      case 'active':
      case 'approved':
        return 'Live';
      case 'pending':
      case 'under_review':
        return 'Under Review';
      case 'sold':
      case 'sold_out':
        return 'Sold Out';
      case 'expired':
        return 'Expired';
      case 'inactive':
        return 'Deactivate';
      case 'soft_rejected':
        return 'Soft Rejected';
      case 'permanent_rejected':
        return 'Perm. Rejected';
      case 'resubmitted':
        return 'Resubmitted';
      case 'featured':
        return 'Featured';
      default:
        return ad.isActive == true ? 'Live' : 'Inactive';
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────
  @override
  void onClose() {
    searchController.dispose();
    _adSubscription?.cancel();
    super.onClose();
  }
}