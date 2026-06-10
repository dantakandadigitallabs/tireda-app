// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/payments/pay_stack/pay_stack_url_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PayStackURLGen {
  static Future payStackURLGen({required String amount, required String secretKey, required String currency, required UserModel userModel}) async {
    const url = "https://api.paystack.co/transaction/initialize";
    final response = await http.post(Uri.parse(url), body: {"email": userModel.email, "amount": amount, "currency": currency}, headers: {"Authorization": "Bearer $secretKey"});
    debugPrint(response.body);
    final data = jsonDecode(response.body);
    if (!data["status"]) {
      debugPrint("Paystack Error: ${data["message"]}");
      return null;
    }
    return PayStackUrlModel.fromJson(data);
  }

  static Future<bool> verifyTransaction({required String reference, required String secretKey, required String amount}) async {
    debugPrint("we Enter payment Settle");
    debugPrint(reference);

    final url = "https://api.paystack.co/transaction/verify/$reference";

    var response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $secretKey"});

    debugPrint(response.body);
    final data = jsonDecode(response.body);
    if (data["status"] == true) {
      if (data["message"] == "Verification successful") {}
    }

    return data["status"];
  }
}