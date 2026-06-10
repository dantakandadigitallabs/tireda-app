import 'dart:async';
import 'package:eSellify/app/constant/toast_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

export 'package:eSellify/app/constant/toast_service.dart' show ToastPosition;

class ShowToastDialog {
  static Timer? _loaderTimer;

  /// Shows the loading spinner and auto-dismisses after 30 seconds
  /// to prevent endless spinning on slow/no network.
  static void showLoader(String message) {
    EasyLoading.show(status: message);

    // Cancel any existing timer first
    _loaderTimer?.cancel();

    // Auto-dismiss after 30 seconds and show a friendly error
    _loaderTimer = Timer(const Duration(seconds: 25), () {
      if (EasyLoading.isShow) {
        EasyLoading.dismiss();
        showError(
          'This is taking longer than expected. Check your network and try again.'.tr,
        );
      }
    });
  }

  /// Dismisses the loader and cancels the timeout timer.
  static void closeLoader() {
    _loaderTimer?.cancel();
    _loaderTimer = null;
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