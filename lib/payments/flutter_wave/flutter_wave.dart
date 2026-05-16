// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';
import 'dart:developer';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FlutterWaveScreen extends StatefulWidget {
  final String initialURl;
  final String callBackUrl;

  const FlutterWaveScreen({super.key, required this.initialURl, required this.callBackUrl});

  @override
  State<FlutterWaveScreen> createState() => _FlutterWaveScreenState();
}

class _FlutterWaveScreenState extends State<FlutterWaveScreen> {
  late WebViewController controller;

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
          onWebResourceError: (WebResourceError error) {
            log("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest navigation) async {
            final urlStr = navigation.url.toLowerCase();
            log("WebView Navigating to: $urlStr");

            // 1. Direct Status Checks
            if (urlStr.contains('status=cancelled') || urlStr.contains('status=failed')) {
              ShowToastDialog.closeLoader();
              Get.back(result: false);
              return NavigationDecision.prevent;
            }

            if (urlStr.contains('status=successful') || urlStr.contains('status=success') || urlStr.contains('transaction_id=')) {
              ShowToastDialog.closeLoader();
              Get.back(result: true);
              return NavigationDecision.prevent;
            }

            // 2. Domain & Path Catch-All (Fixes the stripped URL issue)
            try {
              final uri = Uri.parse(navigation.url);
              final callbackUri = Uri.parse(widget.callBackUrl);

              // Remove trailing slashes to ensure a perfect match
              String navPath = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
              String callPath = callbackUri.path.endsWith('/') ? callbackUri.path.substring(0, callbackUri.path.length - 1) : callbackUri.path;

              // If the WebView hits your callback domain and path, close it!
              if (uri.host == callbackUri.host && navPath == callPath) {
                ShowToastDialog.closeLoader();
                Get.back(result: true); // Assume success since they reached the final page
                return NavigationDecision.prevent;
              }
            } catch (e) {
              log("URI parsing error: $e");
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
          title: TextCustom(title: "Payment".tr),
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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: TextCustom(title: 'Cancel Payment'.tr),
          content: SingleChildScrollView(child: TextCustom(title: "Are you sure you want to cancel the payment?".tr)),
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