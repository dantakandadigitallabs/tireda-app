import 'package:get/get.dart';
import '../controllers/job_applicants_controller.dart';

class JobApplicantsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobApplicantsController>(() => JobApplicantsController());
  }
}
