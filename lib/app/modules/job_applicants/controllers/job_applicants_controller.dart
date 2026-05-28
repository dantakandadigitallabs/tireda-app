import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/job_application_model.dart';
import 'package:eSellify/app/modules/chats/views/chat_detail_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

/// Employer-facing controller: applicants for one of the employer's job ads.
/// Expects Get.arguments: { 'adId': String, 'adTitle': String? }
class JobApplicantsController extends GetxController {
  String adId = '';
  String? adTitle;

  final RxBool isLoading = true.obs;
  final RxList<JobApplicationModel> applicants = <JobApplicationModel>[].obs;

  // 'all' | 'pending' | 'shortlisted' | 'hired' | 'rejected'
  final RxString filter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      adId = (args['adId'] ?? '').toString();
      adTitle = args['adTitle']?.toString();
    }
    loadApplicants();
  }

  Future<void> loadApplicants() async {
    if (adId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      applicants.value = await FireStoreUtils.getApplicationsForAd(adId);
    } finally {
      isLoading.value = false;
    }
  }

  int countFor(String status) => applicants.where((a) => (a.status ?? 'pending').toLowerCase() == status).length;

  List<JobApplicationModel> get filtered => filter.value == 'all' ? applicants : applicants.where((a) => (a.status ?? 'pending').toLowerCase() == filter.value).toList();

  void setFilter(String value) => filter.value = value;

  Future<void> updateStatus(JobApplicationModel app, String status) async {
    ShowToastDialog.showLoader("Updating...".tr);
    final ok = await FireStoreUtils.updateJobApplicationStatus(app.id!, status);
    ShowToastDialog.closeLoader();
    if (ok) {
      app.status = status;
      applicants.refresh();
      ShowToastDialog.showSuccess("application_status".trParams({"status": status}));
    } else {
      ShowToastDialog.showError("Failed to update".tr);
    }
  }

  /// Opens (or creates) an in-app chat between the employer and this applicant.
  Future<void> messageApplicant(JobApplicationModel app) async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null || app.applicantId == null || Constant.userModel == null) {
      ShowToastDialog.showError("Unable to open chat".tr);
      return;
    }
    ShowToastDialog.showLoader("Opening chat...".tr);
    final ad = await FireStoreUtils.getAdById(adId);
    final applicant = await FireStoreUtils.getUserProfile(app.applicantId!);
    if (ad == null || applicant == null) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Unable to open chat".tr);
      return;
    }
    final room = await FireStoreUtils.getOrCreateChatRoomWith(ad: ad, currentUser: Constant.userModel!, otherUser: applicant);
    ShowToastDialog.closeLoader();
    Get.to(() => ChatDetailView(chatRoom: room));
  }
}
