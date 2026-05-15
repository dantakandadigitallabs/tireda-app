// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eSellify/app/constant/collection_name.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/email_template_model.dart';
import 'package:eSellify/app/models/smtp_setting_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailTemplateService {
  static Future<void> sendEmail({
    required String type,
    required Map<String, String> variables,
    required String toEmail,
  }) async {
    try {
      if (toEmail.isEmpty) {
        if (kDebugMode) {
          print('Email is empty, skipping send');
        }
        return;
      }

      // 1. Load SMTP settings from Firestore
      DocumentSnapshot smtpSnapshot = await FirebaseFirestore.instance.collection(CollectionName.settings).doc('smtp_settings').get();

      if (!smtpSnapshot.exists) {
        if (kDebugMode) {
          print('SMTP settings not found');
        }
        return;
      }

      final smtpData = smtpSnapshot.data() as Map<String, dynamic>?;
      if (smtpData == null) {
        if (kDebugMode) {
          print('SMTP data is null');
        }
        return;
      }

      SMTPSettingModel smtp = SMTPSettingModel.fromJson(smtpData);

      // 2. Load the email template
      QuerySnapshot templateSnapshot = await FirebaseFirestore.instance.collection(CollectionName.emailTemplate).where('type', isEqualTo: type).get();

      if (templateSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No email template found for type: $type');
        }
        return;
      }

      final templateData = templateSnapshot.docs.first.data() as Map<String, dynamic>?;
      if (templateData == null) {
        if (kDebugMode) {
          print('Template data is null');
        }
        return;
      }

      EmailTemplateModel template = EmailTemplateModel.fromJson(templateData);

      if (template.status != true) {
        if (kDebugMode) {
          print('Email template for "$type" is inactive. Skipping send.');
        }
        return;
      }

      // 3. Replace placeholders with dynamic values
      String subject = _replacePlaceholders(template.subject ?? '', variables);
      String body = _replacePlaceholders(template.body ?? '', variables);

      // 4. Setup mailer
      final smtpServer = SmtpServer(
        smtp.smtpHost ?? '',
        username: smtp.username ?? '',
        password: smtp.password ?? '',
        port: int.tryParse(smtp.smtpPort ?? '587') ?? 587,
        ignoreBadCertificate: true,
      );

      final message = Message()
        ..from = Address(smtp.username ?? '', Constant.appName.toString())
        ..recipients.add(toEmail)
        ..subject = subject
        ..html = body;

      // 5. Send email
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) {
        print('Email sent: ${sendReport.toString()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Email sending error: $e');
      }
    }
  }

  static String _replacePlaceholders(String text, Map<String, String> variables) {
    if (text.isEmpty) return text;

    String updated = text;
    variables.forEach((key, value) {
      updated = updated.replaceAll('{{$key}}', value).replaceAll('{{ $key }}', value);
    });
    return updated;
  }
}