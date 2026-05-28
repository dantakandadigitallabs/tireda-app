import 'package:get/get.dart';
import '../controllers/job_applications_controller.dart';

class JobApplicationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobApplicationsController>(() => JobApplicationsController());
  }
}
