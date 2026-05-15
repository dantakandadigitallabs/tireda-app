import 'package:eSellify/app/models/contact_us_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ContactUsController extends GetxController {
  Rx<ContactUsModel> contactUsModel = ContactUsModel().obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getContactUs();
    super.onInit();
  }

  void getContactUs() {
    FireStoreUtils.getContactUsInformation().then((value) {
      if (value != null) {
        contactUsModel.value = value;
        isLoading.value = false;
      }
    });
  }
}
