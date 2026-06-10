import 'dart:io';
import 'package:eSellify/app/constant/show_toast.dart';

class NetworkUtils {
  /// Returns true if the device has an active internet connection.
  /// Shows an error toast automatically if there is no connection.
  static Future<bool> isConnected({bool showError = true}) async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    if (showError) {
      ShowToastDialog.showError(
        'No internet connection. Check your network and try again.',
      );
    }
    return false;
  }
}