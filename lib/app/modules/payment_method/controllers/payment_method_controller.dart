// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/subscription_package_model.dart';
import 'package:eSellify/app/models/transaction_model.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/payments/flutter_wave/flutter_wave.dart';
import 'package:eSellify/payments/marcado_pago/mercado_pago_screen.dart';
import 'package:eSellify/payments/midtrans/midtrans_payment_screen.dart';
import 'package:eSellify/payments/pay_fast/pay_fast_screen.dart';
import 'package:eSellify/payments/pay_stack/pay_stack_screen.dart';
import 'package:eSellify/payments/pay_stack/pay_stack_url_model.dart';
import 'package:eSellify/payments/pay_stack/paystack_url_generator.dart';
import 'package:eSellify/payments/paypal/PaypalPayment.dart';
import 'package:eSellify/payments/xendit/xendit_model.dart';
import 'package:eSellify/payments/xendit/xendit_payment_screen.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

    if (pm.strip?.isActive == true) gateways.add({'key': 'stripe', 'name': pm.strip!.name ?? 'Stripe', 'icon': 'assets/images/ig_stripe.png'});
    if (pm.razorpay?.isActive == true) gateways.add({'key': 'razorpay', 'name': pm.razorpay!.name ?? 'Razorpay', 'icon': 'assets/images/ig_razorpay.png'});
    if (pm.paypal?.isActive == true) gateways.add({'key': 'paypal', 'name': pm.paypal!.name ?? 'PayPal', 'icon': 'assets/images/ig_paypal.png'});
    if (pm.payStack?.isActive == true) gateways.add({'key': 'paystack', 'name': pm.payStack!.name ?? 'PayStack', 'icon': 'assets/images/ig_paystack.png'});
    if (pm.flutterWave?.isActive == true) gateways.add({'key': 'flutterwave', 'name': pm.flutterWave!.name ?? 'FlutterWave', 'icon': 'assets/images/ig_flutterwave.png'});
    if (pm.mercadoPago?.isActive == true) gateways.add({'key': 'mercadopago', 'name': pm.mercadoPago!.name ?? 'MercadoPago', 'icon': 'assets/images/ig_marcadopago.png'});
    if (pm.payFast?.isActive == true) gateways.add({'key': 'payfast', 'name': pm.payFast!.name ?? 'PayFast', 'icon': 'assets/images/ig_payfast.png'});
    if (pm.midtrans?.isActive == true) gateways.add({'key': 'midtrans', 'name': pm.midtrans!.name ?? 'Midtrans', 'icon': 'assets/images/ig_midtrans.png'});
    if (pm.xendit?.isActive == true) gateways.add({'key': 'xendit', 'name': pm.xendit!.name ?? 'Xendit', 'icon': 'assets/images/ig_xendit.png'});

    activeGateways.value = gateways;
    if (gateways.isNotEmpty) selectedMethod.value = gateways.first['key'];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROCESS PAYMENT — dispatches to the correct gateway
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> processPayment() async {
    if (selectedMethod.value.isEmpty) {
      ShowToastDialog.showError("Please select a payment method");
      return;
    }
    if (currentUserId == null) {
      ShowToastDialog.showError("Please login to continue");
      return;
    }

    isProcessing.value = true;

    try {
      switch (selectedMethod.value) {
        case 'stripe':
          await _payWithStripe();
          break;
        case 'paypal':
          await _payWithPaypal();
          break;
        case 'razorpay':
          await _payWithRazorpay();
          break;
        case 'paystack':
          await _payWithPayStack();
          break;
        case 'flutterwave':
          await _payWithFlutterWave();
          break;
        case 'mercadopago':
          await _payWithMercadoPago();
          break;
        case 'midtrans':
          await _payWithMidtrans();
          break;
        case 'xendit':
          await _payWithXendit();
          break;
        case 'payfast':
          await _payWithPayFast();
          break;
        default:
          ShowToastDialog.showError("Unsupported payment method");
          isProcessing.value = false;
      }
    } catch (e) {
      developer.log('processPayment Error: $e');
      ShowToastDialog.showError("Payment failed. Please try again.");
      isProcessing.value = false;
    }
  }

  // ─── Stripe (native Payment Sheet) ──────────────────────────────────────────

  Future<void> _payWithStripe() async {
    final stripeConfig = Constant.paymentModel?.strip;
    if (stripeConfig == null) {
      ShowToastDialog.showError("Stripe not configured");
      isProcessing.value = false;
      return;
    }

    try {
      // 1. Set publishable key
      stripe.Stripe.publishableKey = stripeConfig.clientPublishableKey ?? '';

      // 2. Create PaymentIntent on Stripe API
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {'Authorization': 'Bearer ${stripeConfig.stripeSecret}', 'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'amount': (amount * 100).toInt().toString(),
          'currency': currencyCode.toLowerCase(),
          'payment_method_types[]': 'card',
          'description': 'Subscription: ${package.name?.values.firstOrNull ?? "Package"}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        ShowToastDialog.showError(error['error']?['message'] ?? 'Stripe payment failed');
        isProcessing.value = false;
        return;
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['client_secret'] as String;
      final paymentIntentId = data['id'] as String;

      // 3. Initialize Payment Sheet
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: Constant.appName.toString() ?? 'eSellify',
          style: ThemeMode.system,
        ),
      );

      isProcessing.value = false;

      // 4. Present Payment Sheet (shows card input UI)
      await stripe.Stripe.instance.presentPaymentSheet();

      // 5. If we reach here, payment was successful
      await _onPaymentSuccess('stripe', paymentIntentId);
    } on stripe.StripeException catch (e) {
      developer.log('Stripe cancelled/error: ${e.error.localizedMessage}');
      if (e.error.code != stripe.FailureCode.Canceled) {
        ShowToastDialog.showError(e.error.localizedMessage ?? "Stripe payment failed");
      }
      isProcessing.value = false;
    } catch (e) {
      developer.log('Stripe Error: $e');
      ShowToastDialog.showError("Stripe payment failed");
      isProcessing.value = false;
    }
  }

  // ─── PayPal ────────────────────────────────────────────────────────────────

  Future<void> _payWithPaypal() async {
    isProcessing.value = false;

    final result = await Get.to(
      () => PaypalPayment(
        price: amount.toStringAsFixed(2),
        currencyCode: currencyCode,
        title: package.name?.values.firstOrNull ?? 'Subscription',
        description: 'Purchase subscription package',
        onFinish: (paymentId) {
          Get.back();
          if (paymentId != null && paymentId.toString().isNotEmpty) {
            _onPaymentSuccess('paypal', paymentId.toString());
          } else {
            ShowToastDialog.showError("PayPal payment cancelled");
          }
        },
      ),
    );

    if (result == null) {
      isProcessing.value = false;
    }
  }

  // ─── Razorpay (native checkout) ─────────────────────────────────────────────

  Razorpay? _razorpayInstance;

  Future<void> _payWithRazorpay() async {
    final razorpayConfig = Constant.paymentModel?.razorpay;
    if (razorpayConfig == null) {
      ShowToastDialog.showError("Razorpay not configured");
      isProcessing.value = false;
      return;
    }

    try {
      // 1. Create order via Razorpay API
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Basic ${base64Encode(utf8.encode('${razorpayConfig.razorpayKey}:${razorpayConfig.razorpaySecret}'))}'},
        body: jsonEncode({
          'amount': (amount * 100).toInt(),
          'currency': currencyCode,
          'receipt': 'sub_${Constant.getUuid().substring(0, 8)}',
        }),
      );

      if (response.statusCode != 200) {
        ShowToastDialog.showError("Razorpay order creation failed");
        isProcessing.value = false;
        return;
      }

      final orderData = jsonDecode(response.body);
      final orderId = orderData['id'];

      // 2. Open native Razorpay checkout
      _razorpayInstance?.clear();
      _razorpayInstance = Razorpay();

      _razorpayInstance!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse res) {
        _razorpayInstance?.clear();
        _onPaymentSuccess('razorpay', res.paymentId ?? orderId);
      });

      _razorpayInstance!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse res) {
        _razorpayInstance?.clear();
        isProcessing.value = false;
        ShowToastDialog.showError(res.message ?? "Razorpay payment failed");
      });

      _razorpayInstance!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse res) {
        _razorpayInstance?.clear();
        isProcessing.value = false;
        ShowToastDialog.showWarning("External wallet: ${res.walletName}");
      });

      isProcessing.value = false;

      _razorpayInstance!.open({
        'key': razorpayConfig.razorpayKey ?? '',
        'amount': (amount * 100).toInt(),
        'currency': currencyCode,
        'order_id': orderId,
        'name': Constant.appName.toString(),
        'description': 'Subscription: ${package.name?.values.firstOrNull ?? "Package"}',
        'prefill': {
          'contact': Constant.userModel?.phoneNumber?.toString() ?? '',
          'email': Constant.userModel?.email?.toString() ?? '',
        },
        'theme': {'color': '#068FFF'},
      });
    } catch (e) {
      developer.log('Razorpay Error: $e');
      ShowToastDialog.showError("Razorpay payment failed");
      isProcessing.value = false;
    }
  }

  // ─── PayStack ──────────────────────────────────────────────────────────────

  Future<void> _payWithPayStack() async {
    final payStack = Constant.paymentModel?.payStack;
    if (payStack == null || Constant.userModel == null) {
      ShowToastDialog.showError("PayStack not configured");
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
          ShowToastDialog.showError("PayStack payment cancelled");
        }
      } else {
        ShowToastDialog.showError("Failed to initialize PayStack");
      }
    } catch (e) {
      developer.log('PayStack Error: $e');
      ShowToastDialog.showError("PayStack payment failed");
      isProcessing.value = false;
    }
  }

  // ─── FlutterWave ───────────────────────────────────────────────────────────

  Future<void> _payWithFlutterWave() async {
    final fw = Constant.paymentModel?.flutterWave;
    if (fw == null) {
      ShowToastDialog.showError("FlutterWave not configured");
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
            ShowToastDialog.showError("FlutterWave payment cancelled");
          }
        } else {
          ShowToastDialog.showError(data['message'] ?? "FlutterWave initialization failed");
        }
      } else {
        ShowToastDialog.showError("FlutterWave API error");
      }
    } catch (e) {
      developer.log('FlutterWave Error: $e');
      ShowToastDialog.showError("FlutterWave payment failed");
      isProcessing.value = false;
    }
  }

  // ─── MercadoPago ───────────────────────────────────────────────────────────

  Future<void> _payWithMercadoPago() async {
    final mp = Constant.paymentModel?.mercadoPago;
    if (mp == null) {
      ShowToastDialog.showError("MercadoPago not configured");
      isProcessing.value = false;
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.mercadopago.com/checkout/preferences'),
        headers: {'Authorization': 'Bearer ${mp.mercadoPagoAccessToken}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': [
            {'title': package.name?.values.firstOrNull ?? 'Subscription', 'quantity': 1, 'unit_price': amount, 'currency_id': currencyCode},
          ],
          'back_urls': {'success': mp.callBackUrl ?? '', 'failure': mp.callBackUrl ?? '', 'pending': mp.callBackUrl ?? ''},
          'auto_return': 'approved',
        }),
      );

      isProcessing.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final url = data['init_point'] ?? data['sandbox_init_point'];
        if (url != null) {
          final payResult = await Get.to(() => MercadoPagoScreen(initialURl: url, callBackUrl: mp.callBackUrl ?? ''));

          if (payResult == true) {
            await _onPaymentSuccess('mercadopago', data['id']?.toString() ?? Constant.getUuid());
          } else {
            ShowToastDialog.showError("MercadoPago payment cancelled");
          }
        } else {
          ShowToastDialog.showError("MercadoPago initialization failed");
        }
      } else {
        ShowToastDialog.showError("MercadoPago API error");
      }
    } catch (e) {
      developer.log('MercadoPago Error: $e');
      ShowToastDialog.showError("MercadoPago payment failed");
      isProcessing.value = false;
    }
  }

  // ─── Midtrans ──────────────────────────────────────────────────────────────

  Future<void> _payWithMidtrans() async {
    final mt = Constant.paymentModel?.midtrans;
    if (mt == null) {
      ShowToastDialog.showError("Midtrans not configured");
      isProcessing.value = false;
      return;
    }

    try {
      final orderId = 'sub_${Constant.getUuid().substring(0, 12)}';
      final baseUrl = mt.isSandbox == true ? 'https://app.sandbox.midtrans.com/snap/v1/transactions' : 'https://app.midtrans.com/snap/v1/transactions';

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Basic ${base64Encode(utf8.encode('${mt.midtransSecretKey}:'))}'},
        body: jsonEncode({
          'transaction_details': {'order_id': orderId, 'gross_amount': amount.toInt()},
          'customer_details': {'first_name': Constant.userModel?.firstName ?? '', 'email': Constant.userModel?.email ?? ''},
        }),
      );

      isProcessing.value = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final redirectUrl = data['redirect_url'];
        if (redirectUrl != null) {
          final payResult = await Get.to(() => MidtransPaymentScreen(paymentUrl: redirectUrl));

          if (payResult == true) {
            await _onPaymentSuccess('midtrans', orderId);
          } else {
            ShowToastDialog.showError("Midtrans payment cancelled");
          }
        } else {
          ShowToastDialog.showError("Midtrans initialization failed");
        }
      } else {
        ShowToastDialog.showError("Midtrans API error");
      }
    } catch (e) {
      developer.log('Midtrans Error: $e');
      ShowToastDialog.showError("Midtrans payment failed");
      isProcessing.value = false;
    }
  }

  // ─── Xendit ────────────────────────────────────────────────────────────────

  Future<void> _payWithXendit() async {
    final orderId = 'sub_${Constant.getUuid().substring(0, 12)}';

    final value = await createXenditInvoice(orderId);
    if (value != null) {
      final result = await Get.to(() => XenditPaymentScreen(apiKey: Constant.paymentModel!.xendit!.xenditSecretKey.toString(), transId: value.id, invoiceUrl: value.invoiceUrl));
      if (result == true) {
        await _onPaymentSuccess('xendit', orderId);
      } else {
        log("====>Payment Faild");
      }
    }
  }

  Future<XenditModel?> createXenditInvoice(String externalId) async {
    final xn = Constant.paymentModel?.xendit;
    if (xn == null) {
      ShowToastDialog.showError("Xendit not configured");
      isProcessing.value = false;
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.xendit.co/v2/invoices'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Basic ${base64Encode(utf8.encode('${xn.xenditSecretKey}:'))}'},
        body: jsonEncode({
          'external_id': externalId,
          'amount': amount,
          'payer_email': Constant.userModel?.email ?? '',
          'description': 'Subscription: ${package.name?.values.firstOrNull ?? "Package"}',
          'currency': currencyCode,
        }),
      );

      isProcessing.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final invoiceUrl = data['invoice_url'];
        final invoiceId = data['id'];

        if (invoiceUrl != null) {
          final payResult = await Get.to(() => XenditPaymentScreen(invoiceUrl: invoiceUrl, transId: invoiceId, apiKey: xn.xenditSecretKey));

          if (payResult == true) {
            await _onPaymentSuccess('xendit', invoiceId ?? Constant.getUuid());
          } else {
            ShowToastDialog.showError("Xendit payment cancelled");
          }
        } else {
          ShowToastDialog.showError("Xendit initialization failed");
        }
      } else {
        ShowToastDialog.showError("Xendit API error");
      }
    } catch (e) {
      developer.log('Xendit Error: $e');
      ShowToastDialog.showError("Xendit payment failed");
      isProcessing.value = false;
    }
    return null;
  }

  // ─── PayFast ───────────────────────────────────────────────────────────────

  Future<void> _payWithPayFast() async {
    final pf = Constant.paymentModel?.payFast;
    if (pf == null) {
      ShowToastDialog.showError("PayFast not configured");
      isProcessing.value = false;
      return;
    }

    isProcessing.value = false;

    final htmlData =
        '''
      <html><body onload="document.forms[0].submit();">
        <form method="POST" action="https://${pf.isSandbox == true ? 'sandbox' : 'www'}.payfast.co.za/eng/process">
          <input type="hidden" name="merchant_id" value="${pf.merchantId}">
          <input type="hidden" name="merchant_key" value="${pf.merchantKey}">
          <input type="hidden" name="return_url" value="${pf.returnUrl}">
          <input type="hidden" name="cancel_url" value="${pf.cancelUrl}">
          <input type="hidden" name="notify_url" value="${pf.notifyUrl}">
          <input type="hidden" name="amount" value="${amount.toStringAsFixed(2)}">
          <input type="hidden" name="item_name" value="${package.name?.values.firstOrNull ?? 'Subscription'}">
          <input type="hidden" name="email_address" value="${Constant.userModel?.email ?? ''}">
        </form>
      </body></html>
    ''';

    final payResult = await Get.to(() => PayFastScreen(htmlData: htmlData, payFastSettingData: pf));

    if (payResult == true) {
      await _onPaymentSuccess('payfast', 'pf_${Constant.getUuid()}');
    } else {
      ShowToastDialog.showError("PayFast payment cancelled");
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

      // Cancel any existing active subscription of the same type
      await FireStoreUtils.cancelActiveSubscriptions(uid, package.type ?? 'ad_listing');

      // Count current active ads for this user
      final currentActiveAds = package.type == 'featured_ads'
          ? await FireStoreUtils.countUserFeaturedAds(uid)
          : await FireStoreUtils.countUserActiveAds(uid);

      // Calculate expiry date
      Timestamp? expiryDate;
      if (package.isUnlimited != true && package.packageDuration != null) {
        expiryDate = Timestamp.fromDate(DateTime.now().add(Duration(days: package.packageDuration!)));
      }

      final packageName = package.name?.values.firstOrNull ?? '';

      // Create subscription
      final subscription = UserSubscriptionModel(
        id: subscriptionId,
        userId: uid,
        packageId: package.id,
        packageName: packageName,
        packageImage: package.image,
        packageType: package.type,
        price: amount,
        status: 'active',
        purchaseDate: Timestamp.now(),
        expiryDate: expiryDate,
        adsPosted: currentActiveAds,
        adLimit: package.itemLimit ?? 0,
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
      ShowToastDialog.showSuccess("Purchase successful!");
      Get.back(result: true);
    } catch (e) {
      isProcessing.value = false;
      ShowToastDialog.showError("Failed to save subscription: $e");
    }
  }

  @override
  void onClose() {
    _razorpayInstance?.clear();
    super.onClose();
  }
}
