import 'dart:developer';
import 'dart:io';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String paymentUrl;

  const MidtransPaymentScreen({super.key, required this.paymentUrl});

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            log("Midtrans :: ${request.url}");
            if (Platform.isIOS) {
              if (request.url.contains('/success')) {
                Get.back(result: true);
              } else if (request.url.contains('/failed')) {
                Get.back(result: false);
              }
            } else {
              String? orderId = Uri.parse(request.url).queryParameters['tref'];
              if (orderId != null) {
                Get.back(result: true);
              } else {
                Get.back(result: false);
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TextCustom(title: "Midtrans Payment")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
