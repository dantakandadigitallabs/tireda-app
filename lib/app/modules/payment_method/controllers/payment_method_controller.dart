// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/subscription_package_model.dart';
import 'package:eSellify/app/models/transaction_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/payments/flutter_wave/flutter_wave.dart';
import 'package:eSellify/payments/pay_stack/pay_stack_screen.dart';
import 'package:eSellify/payments/pay_stack/pay_stack_url_model.dart';
import 'package:eSellify/payments/pay_stack/paystack_url_generator.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Tireda Custom: only PayStack and FlutterWave are wired up — Stripe,
// PayPal, Razorpay, MercadoPago, Midtrans, Xendit, and PayFast are
// intentionally not ported from eSellify 1.5. Nigerian market only needs
// these two gateways; the rest are dead weight. Do not reintroduce them
// on future merges without an explicit decision to do so.
class PaymentMethodController extends GetxController {
  late SubscriptionPackageModel package;
  RxBool isProcessing = false.obs;
  RxString selectedMethod = ''.obs;
  RxList<Map<String, dynamic>> activeGateways = <Map<String, dynamic>>[].obs;

  String? get currentUserId => FireStoreUtils.getCurrentUid();

  double get amount => package.finalPrice ?? package.price ?? 0;

  String get currencyCode => Constant.currencyModel?.code ?? 'USD';

  String get currencySymbol => Constant.currencyModel?.symbol ?? '\$';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is SubscriptionPackageModel) {
      package = args;
    }
    _loadActiveGateways();
  }

  void _loadActiveGateways() {
    final pm = Constant.paymentModel;
    if (pm == null) return;
    final gateways = <Map<String, dynamic>>[];

    if (pm.payStack?.isActive == true) gateways.add({'key': 'paystack', 'name': pm.payStack!.name ?? 'PayStack', 'icon': 'assets/images/ig_paystack.png'});
    if (pm.flutterWave?.isActive == true) gateways.add({'key': 'flutterwave', 'name': pm.flutterWave!.name ?? 'FlutterWave', 'icon': 'assets/images/ig_flutterwave.png'});

    activeGateways.value = gateways;
    if (gateways.isNotEmpty) selectedMethod.value = gateways.first['key'];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROCESS PAYMENT — dispatches to the correct gateway
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> processPayment() async {
    if (selectedMethod.value.isEmpty) {
      ShowToastDialog.showError("Please select a payment method".tr);
      return;
    }
    if (currentUserId == null) {
      ShowToastDialog.showError("Please login to continue".tr);
      return;
    }

    isProcessing.value = true;

    try {
      switch (selectedMethod.value) {
        case 'paystack':
          await _payWithPayStack();
          break;
        case 'flutterwave':
          await _payWithFlutterWave();
          break;
        default:
          ShowToastDialog.showError("Unsupported payment method".tr);
          isProcessing.value = false;
      }
    } catch (e) {
      developer.log('processPayment Error: $e');
      ShowToastDialog.showError("Payment failed. Please try again.".tr);
      isProcessing.value = false;
    }
  }


  // ─── PayStack ──────────────────────────────────────────────────────────────

  Future<void> _payWithPayStack() async {
    final payStack = Constant.paymentModel?.payStack;
    if (payStack == null || Constant.userModel == null) {
      ShowToastDialog.showError("PayStack not configured".tr);
      isProcessing.value = false;
      return;
    }

    try {
      final result = await PayStackURLGen.payStackURLGen(
        amount: (amount * 100).toInt().toString(),
        secretKey: payStack.payStackSecret ?? '',
        currency: currencyCode,
        userModel: Constant.userModel!,
      );

      isProcessing.value = false;

      if (result != null && result is PayStackUrlModel) {
        final payResult = await Get.to(
              () => PayStackScreen(
            initialURl: result.data.authorizationUrl,
            reference: result.data.reference,
            amount: amount.toString(),
            secretKey: payStack.payStackSecret ?? '',
            callBackUrl: payStack.callBackUrl ?? '',
          ),
        );

        if (payResult == true) {
          await _onPaymentSuccess('paystack', result.data.reference);
        } else {
          ShowToastDialog.showError("PayStack payment cancelled".tr);
        }
      } else {
        ShowToastDialog.showError("Failed to initialize PayStack".tr);
      }
    } catch (e) {
      developer.log('PayStack Error: $e');
      ShowToastDialog.showError("PayStack payment failed".tr);
      isProcessing.value = false;
    }
  }

  // ─── FlutterWave ───────────────────────────────────────────────────────────

  Future<void> _payWithFlutterWave() async {
    final fw = Constant.paymentModel?.flutterWave;
    if (fw == null) {
      ShowToastDialog.showError("FlutterWave not configured".tr);
      isProcessing.value = false;
      return;
    }

    try {
      final txRef = 'sub_${Constant.getUuid().substring(0, 12)}';
      final user = Constant.userModel;

      final response = await http.post(
        Uri.parse('https://api.flutterwave.com/v3/payments'),
        headers: {'Authorization': 'Bearer ${fw.secretKey}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'tx_ref': txRef,
          'amount': amount.toString(),
          'currency': currencyCode,
          // Tireda Custom: branded callback fallback (1.5 base reverted this
          // to esellify.com — not taken).
          'redirect_url': fw.callBackUrl ?? 'https://tireda.ng/callback',
          'customer': {'email': user?.email ?? '', 'name': user?.fullNameString() ?? ''},
          'payment_options': 'card,banktransfer,ussd',
        }),
      );

      isProcessing.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data']?['link'] != null) {
          final payResult = await Get.to(() => FlutterWaveScreen(initialURl: data['data']['link'], callBackUrl: fw.callBackUrl ?? 'https://tireda.ng/callback'));

          if (payResult == true) {
            await _onPaymentSuccess('flutterwave', txRef);
          } else {
            ShowToastDialog.showError("FlutterWave payment cancelled".tr);
          }
        } else {
          ShowToastDialog.showError(data['message'] ?? "FlutterWave initialization failed".tr);
        }
      } else {
        ShowToastDialog.showError("FlutterWave API error".tr);
      }
    } catch (e) {
      developer.log('FlutterWave Error: $e');
      ShowToastDialog.showError("FlutterWave payment failed".tr);
      isProcessing.value = false;
    }
  }



  // ═══════════════════════════════════════════════════════════════════════════
  // ON PAYMENT SUCCESS — creates subscription + transaction in Firestore
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onPaymentSuccess(String method, String gatewayTransactionId) async {
    isProcessing.value = true;
    try {
      final uid = currentUserId!;
      final user = Constant.userModel;
      final subscriptionId = Constant.getUuid();
      final transactionId = Constant.getUuid();

      // Tireda Custom: additive upgrade — see FireStoreUtils.mergeOrCreateSubscription().
      // NOTE: 1.5 base replaced this with cancelActiveSubscriptions() (destructive
      // replace, discards unused allowance). NOT taken — conflicts directly with
      // Tireda's additive subscription model (same reasoning as
      // SubscriptionsController._directFreePurchase).
      final carriedAllowance = await FireStoreUtils.mergeOrCreateSubscription(
        userId: uid,
        packageType: package.type ?? 'ad_listing',
      );

      // Count current active ads for this user
      final currentActiveAds = package.type == 'featured_ads'
          ? await FireStoreUtils.countUserFeaturedAds(uid)
          : await FireStoreUtils.countUserActiveAds(uid);

      // Calculate expiry date
      Timestamp? expiryDate;
      if (package.isUnlimited != true && package.packageDuration != null) {
        expiryDate = Timestamp.fromDate(DateTime.now().add(Duration(days: package.packageDuration!)));
      }

      // Tireda Custom Merge (eSellify 1.5): snapshot the whole per-language
      // name map so downstream docs can render in any language later, with
      // proper default → en → first-non-empty fallback (replaces the
      // previous `package.name?.values.firstOrNull`, which grabbed an
      // arbitrary language with no defined order).
      final Map<String, String>? packageNameMap = (package.name != null && package.name!.isNotEmpty)
          ? Map<String, String>.from(package.name!)
          : null;
      final packageName = (packageNameMap?['default'] ?? '').isNotEmpty
          ? packageNameMap!['default']!
          : (packageNameMap?['en'] ?? packageNameMap?.values.firstOrNull ?? '');

      // Create subscription
      final subscription = UserSubscriptionModel(
        id: subscriptionId,
        userId: uid,
        packageId: package.id,
        packageName: packageName,
        packageNameTranslations: packageNameMap,
        packageImage: package.image,
        packageType: package.type,
        price: amount,
        status: 'active',
        purchaseDate: Timestamp.now(),
        expiryDate: expiryDate,
        adsPosted: currentActiveAds,
        // Tireda Custom: add carried-forward unused allowance — see mergeOrCreateSubscription().
        adLimit: (package.itemLimit ?? 0) + carriedAllowance,
        isItemLimitUnlimited: package.isItemLimitUnlimited ?? false,
        listingDurationType: package.listingDurationType,
        customDuration: package.customDuration,
        packageDuration: package.packageDuration,
        paymentId: transactionId,
        paymentMethod: method,
      );

      // Create transaction
      final transaction = TransactionModel(
        id: transactionId,
        userId: uid,
        userName: user?.fullNameString(),
        userEmail: user?.email,
        packageId: package.id,
        packageName: packageName,
        packageNameTranslations: packageNameMap,
        packageType: package.type,
        amount: amount,
        currency: currencySymbol,
        paymentMethod: method,
        paymentStatus: 'success',
        transactionId: gatewayTransactionId,
        subscriptionId: subscriptionId,
        createdAt: Timestamp.now(),
      );

      await Future.wait([FireStoreUtils.createUserSubscription(subscription), FireStoreUtils.createTransaction(transaction)]);

      // Refresh wallet balance
      if (method == 'wallet') {
        final updatedUser = await FireStoreUtils.getUserProfile(uid);
        if (updatedUser != null) Constant.userModel = updatedUser;
      }

      isProcessing.value = false;
      ShowToastDialog.showSuccess("Purchase successful!".tr);
      Get.back(result: true);
    } catch (e) {
      isProcessing.value = false;
      ShowToastDialog.showError("${"Failed to save subscription".tr}: $e");
    }
  }

}