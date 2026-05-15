// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MercadoPagoScreen extends StatefulWidget {
  final String initialURl;
  final String callBackUrl;

  const MercadoPagoScreen({super.key, required this.initialURl, required this.callBackUrl});

  @override
  State<MercadoPagoScreen> createState() => _MercadoPagoScreenState();
}

class _MercadoPagoScreenState extends State<MercadoPagoScreen> {
  WebViewController controller = WebViewController();

  @override
  void initState() {
    initController();
    super.initState();
  }

  void initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest navigation) async {
            final url = navigation.url;
            debugPrint("Current URL: $url");

            if (url.contains("success")) {
              Get.back(result: true);
              return NavigationDecision.prevent;
            } else if (url.contains("failure") || url.contains("pending")) {
              Get.back(result: false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialURl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showMyDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const TextCustom(title: "Marcado Pago Payment"),
          centerTitle: false,
          leading: GestureDetector(
            onTap: () {
              _showMyDialog();
            },
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: WebViewWidget(controller: controller),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: TextCustom(title: 'Cancel Payment'.tr),
          content: SingleChildScrollView(child: TextCustom(title: "Are you want to cancel the payment?".tr)),
          actions: <Widget>[
            TextButton(
              child: TextCustom(title: 'No'.tr, color: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: TextCustom(title: 'Yes'.tr, color: Colors.green),
              onPressed: () {
                Navigator.of(context).pop();
                Get.back(result: false);
              },
            ),
          ],
        );
      },
    );
  }
}
