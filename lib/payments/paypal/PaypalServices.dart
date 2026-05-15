// ignore_for_file: depend_on_referenced_packages, file_names, prefer_interpolation_to_compose_strings, strict_top_level_inference

import 'dart:convert';
import 'package:eSellify/app/constant/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert' as convert;

class PaypalServices {
  // for getting the access token from Paypal
  Future<String> getAccessToken() async {
    try {
      final clientId = Constant.paymentModel!.paypal!.paypalClient!;
      final secret = Constant.paymentModel!.paypal!.paypalSecret!;

      // Encode credentials in base64
      final credentials = base64Encode(utf8.encode('$clientId:$secret'));

      final url = Uri.parse('${Constant.paymentModel!.paypal!.isSandbox! ? "https://api-m.sandbox.paypal.com" : "https://api.paypal.com"}/v1/oauth2/token');

      final response = await http.post(
        url,
        headers: {'Authorization': 'Basic $credentials', 'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body["access_token"];
      } else {
        print('Error: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      rethrow;
    }
  }

  // for creating the payment request with Paypal
  Future<Map<String, String>?> createPaypalPayment(transactions, accessToken) async {
    try {
      var response = await http.post(
        Uri.parse("${Constant.paymentModel!.paypal!.isSandbox! ? "https://api-m.sandbox.paypal.com" : "https://api.paypal.com"}/v2/checkout/orders"),
        body: convert.jsonEncode(transactions),
        headers: {"content-type": "application/json", 'Authorization': 'Bearer ' + accessToken},
      );
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (body["links"] != null && body["links"].length > 0) {
          List links = body["links"];

          String executeUrl = "";
          String approvalUrl = "";
          String id = body["id"];
          final item = links.firstWhere((o) => o["rel"] == "approve", orElse: () => null);
          if (item != null) {
            approvalUrl = item["href"];
          }
          final item1 = links.firstWhere((o) => o["rel"] == "authorize", orElse: () => null);
          if (item1 != null) {
            executeUrl = item1["href"];
          }
          return {"executeUrl": executeUrl, "approvalUrl": approvalUrl, "id": id};
        }
        return null;
      } else {
        throw Exception(body["details"][0]["description"]);
      }
    } catch (e) {
      rethrow;
    }
  }

  // for executing the payment transaction
  Future<String?> authorizePayment(url, payerId, accessToken) async {
    try {
      var response = await http.post(url, body: convert.jsonEncode({"payer_id": payerId}), headers: {"content-type": "application/json", 'Authorization': 'Bearer ' + accessToken});

      Map<String, dynamic> body = convert.jsonDecode(response.body);
      if (response.body.contains('purchase_units') && response.body.contains('payments') && response.body.contains('authorizations')) {
        return body["purchase_units"][0]["payments"]["authorizations"][0]["id"];
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
