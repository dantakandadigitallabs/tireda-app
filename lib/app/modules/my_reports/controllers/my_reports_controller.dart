import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/ad_report_model.dart';
import 'package:eSellify/app/modules/ad_listing_detail/views/ad_listing_detail_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class MyReportsController extends GetxController {
  RxList<AdReportModel> reports = <AdReportModel>[].obs;
  RxBool isLoading = true.obs;
  RxString selectedFilter = 'all'.obs;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  List<AdReportModel> get filteredReports {
    if (selectedFilter.value == 'all') return reports;
    return reports.where((r) => r.status == selectedFilter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    reports.value = await FireStoreUtils.getMyReports(uid);
    isLoading.value = false;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  int countByStatus(String status) {
    return reports.where((r) => r.status == status).length;
  }

  /// Navigate to the reported ad's detail screen
  Future<void> openReportedAd(String? adId) async {
    if (adId == null) return;
    ShowToastDialog.showLoader("Loading ad...");
    final ad = await FireStoreUtils.getAdById(adId);
    ShowToastDialog.closeLoader();
    if (ad != null) {
      Get.to(() => const AdListingDetailView(), arguments: {"ad": ad});
    } else {
      ShowToastDialog.showError("This ad is no longer available");
    }
  }
}
