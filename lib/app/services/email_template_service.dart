import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';

class EmailTemplateService {
  static Future<void> sendEmail({required String type, required Map<String, String> variables, required String toEmail}) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendTransactionalEmail');

      final response = await callable.call({"type": type, "to": toEmail, "variables": variables});

      log("Email sent: ${response.data}");
    } catch (e) {
      log("Email error: $e");
    }
  }
}
