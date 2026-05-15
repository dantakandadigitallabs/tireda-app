import 'package:eSellify/app/constant/toast_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

export 'package:eSellify/app/constant/toast_service.dart' show ToastPosition;

class ShowToastDialog {
  static void showLoader(String message) {
    EasyLoading.show(status: message);
  }

  static void closeLoader() {
    EasyLoading.dismiss();
  }

  static void showSuccess(String message, {ToastPosition position = ToastPosition.top}) {
    ToastService().showSuccessToast(message, position: position);
  }

  static void showError(String message, {ToastPosition position = ToastPosition.top}) {
    ToastService().showErrorToast(message, position: position);
  }

  static void showWarning(String message, {ToastPosition position = ToastPosition.top}) {
    ToastService().showWarningToast(message, position: position);
  }
}
