// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:eSellify/payments/xendit/xendit_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class XenditController extends GetxController {
  final String invoiceUrl;
  final String transId;
  final String apiKey; // ⚠️ In production, use Firebase Functions instead!

  XenditController({required this.invoiceUrl, required this.transId, required this.apiKey});

  late WebViewController webViewController;
  RxBool isLoading = true.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    initWebView();
    startPollingTransaction();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// Initialize WebView controller
  void initWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            isLoading.value = false;
          },
          onNavigationRequest: (navigation) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(invoiceUrl));
  }

  /// Poll Xendit for payment status
  void startPollingTransaction() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final value = await checkStatus(paymentId: transId);

      if (value.status == 'PAID' || value.status == 'SETTLED') {
        timer.cancel();
        Get.back(result: true);
      } else if (value.status == 'FAILED' || value.status == 'EXPIRED') {
        timer.cancel();
        Get.back(result: false);
      }
    });
  }

  /// Call Xendit API to check status
  Future<XenditModel> checkStatus({required String paymentId}) async {
    var url = Uri.parse('https://api.xendit.co/v2/invoices/$paymentId');
    var headers = {'Content-Type': 'application/json', 'Authorization': generateBasicAuthHeader(apiKey)};

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return XenditModel.fromJson(jsonDecode(response.body));
      } else {
        log("Check status failed: ${response.body}");
        return XenditModel(status: "FAILED");
      }
    } catch (e) {
      log("Error checking status: $e");
      return XenditModel(status: "FAILED");
    }
  }

  /// Encode key to Basic Auth
  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }
}
