import 'package:eSellify/app/models/job_application_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

/// Applicant-facing controller: loads the jobs the logged-in user applied to.
class JobApplicationsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<JobApplicationModel> applications = <JobApplicationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadApplications();
  }

  Future<void> loadApplications() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      applications.value = await FireStoreUtils.getMyJobApplications(uid);
    } finally {
      isLoading.value = false;
    }
  }
}
