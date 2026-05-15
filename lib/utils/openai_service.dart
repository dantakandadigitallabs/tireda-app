// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/models/custom_field_model.dart';
import 'package:http/http.dart' as http;

/// One leaf-category candidate offered to the AI for classification.
class AiCategoryCandidate {
  final String id;
  final String fullPath; // e.g. "Vehicles > Cars > Sedan"

  AiCategoryCandidate({required this.id, required this.fullPath});
}

/// Result of an OpenAI ad-generation call.
class AiGeneratedAd {
  final String? title;
  final String? description;
  /// ID of the category the AI thinks best matches the photo. Null if the
  /// AI couldn't decide or no candidates were supplied.
  final String? suggestedCategoryId;
  /// Human-readable category name from the AI (fallback when matching
  /// against [AiCategoryCandidate] list isn't possible).
  final String? suggestedCategoryName;
  final double? suggestedPrice;
  /// Map of custom-field name → AI-suggested value.
  /// For multi-select / radio types the value is a comma-separated string
  /// of options that the AI thinks apply.
  final Map<String, String> customFieldValues;

  AiGeneratedAd({
    this.title,
    this.description,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.suggestedPrice,
    this.customFieldValues = const {},
  });
}

/// OpenAI service for auto-generating ad content from photos + product name.
///
/// Uses the Chat Completions endpoint with vision (multimodal) input.
/// Configuration (API key, model, enabled flag) is loaded from the
/// `settings/openai_config` Firestore document at app start into
/// [Constant.openAiConfig].
///
/// SECURITY NOTE: the API key is read on the client. This matches the
/// project's existing pattern for Stripe/Razorpay keys but is inherently
/// less secure than a server-side proxy (e.g. a Cloud Function).
class OpenAiService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  /// Returns true if a valid configuration is loaded and the feature is
  /// enabled by admin.
  static bool get isEnabled => Constant.openAiConfig.isUsable;

  /// Generates ad content from one or more product photos + an optional
  /// product name and category context.
  ///
  /// [images] - list of image files (main + other photos). At least one
  ///            image is required.
  /// [productName] - optional user-provided product/title hint.
  /// [category] - leaf category the ad belongs to (helps prompting).
  /// [customFields] - active custom fields for the chosen category. The AI
  ///                  is asked to fill these in using its JSON output.
  ///
  /// Returns null if generation fails or feature is disabled.
  static Future<AiGeneratedAd?> generateAdFromPhotos({
    required List<File> images,
    String? productName,
    CategoryModel? category,
    List<CustomFieldModel> customFields = const [],
    List<AiCategoryCandidate> availableCategories = const [],
  }) async {
    if (!isEnabled) return null;
    if (images.isEmpty) return null;

    final cfg = Constant.openAiConfig;
    final model = (cfg.model?.isNotEmpty ?? false) ? cfg.model! : 'gpt-4o-mini';

    // ── Build prompt ───────────────────────────────────────────────
    final fieldsSpec = customFields
        .where((f) => (f.active ?? true) == true)
        .map((f) {
      final type = f.type ?? 'text';
      final opts = (f.options != null && f.options!.isNotEmpty) ? ' (options: ${f.options!.join(", ")})' : '';
      return '- "${f.name}" [type: $type$opts]';
    }).join('\n');

    // Categories block — only include if we have candidates.
    String categoriesBlock = '';
    if (availableCategories.isNotEmpty) {
      // Limit to keep token use reasonable
      final list = availableCategories.take(300).toList();
      final lines = list.map((c) => '${c.id}\t${c.fullPath.replaceAll("\t", " ")}').join('\n');
      categoriesBlock = '''

CATEGORY CLASSIFICATION:
You MUST classify the product into ONE category from the list below.
${category != null ? 'The user picked "${category.categoryName}" but THIS MAY BE WRONG. Look at the photo — if it doesn\'t match, OVERRIDE the selection.' : ''}

Categories (format: ID<TAB>PATH, one per line):
$lines

Return the exact ID (the part before the tab) of the best-matching category in the "categoryId" field below. Do NOT make up an ID — copy one verbatim from the list.
''';
    }

    final defaultPrompt = '''
You are an expert at writing online classified ads (like OLX/Marketplace) AND a precise product classifier.
Look at the provided product photo(s)${productName != null && productName.isNotEmpty ? ' and the user-provided product hint: "$productName"' : ''}.
$categoriesBlock
Return ONLY this JSON object (no markdown fence, no commentary):
{
  "title": "Short catchy title (max 60 chars)",
  "description": "Detailed 3-5 sentence description highlighting condition, features and selling points.",
  "categoryId": "<copy-paste an ID verbatim from the list above; null only if there is truly no remotely matching category>",
  "suggestedCategory": "Human-readable name of that category (e.g. 'Mobile Phones')",
  "suggestedPrice": <number or null — reasonable resale price>,
  "customFields": ${customFields.isEmpty ? '{}' : '{ /* keys = field names below; values = your best guess from the photo */ \n$fieldsSpec\n}'}
}
''';

    final promptText = (cfg.prompt?.isNotEmpty ?? false) ? cfg.prompt! : defaultPrompt;

    // ── Build vision message ───────────────────────────────────────
    // Cap at 6 to balance accuracy against token cost (~85k tokens at high
    // detail x 6 images would be excessive; OpenAI auto-resizes).
    final attachedImages = images.take(6).toList();
    final imgCountNote = attachedImages.length > 1
        ? '\n\nIMPORTANT: ${attachedImages.length} photos of the SAME product are attached, taken from different angles/views. Use ALL of them together when writing the description and filling custom fields (e.g. one photo may show condition, another the brand label, another the back).'
        : '';
    final List<Map<String, dynamic>> userContent = [
      {'type': 'text', 'text': promptText + imgCountNote},
    ];
    for (final img in attachedImages) {
      try {
        final Uint8List bytes = await img.readAsBytes();
        final b64 = base64Encode(bytes);
        userContent.add({
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$b64'},
        });
      } catch (e) {
        print('OpenAiService: failed to encode image: $e');
      }
    }

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': userContent},
      ],
      'response_format': {'type': 'json_object'},
      'max_tokens': 800,
      'temperature': 0.7,
    });

    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${cfg.apiKey}',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (resp.statusCode != 200) {
        print('OpenAiService: ${resp.statusCode} ${resp.body}');
        return null;
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final msg = choices.first['message'] as Map<String, dynamic>?;
      final content = msg?['content']?.toString() ?? '';
      if (content.isEmpty) return null;

      // Strip optional markdown fences
      var jsonStr = content.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```(json)?'), '').replaceAll(RegExp(r'```$'), '').trim();
      }

      final Map<String, dynamic> parsed = jsonDecode(jsonStr);
      final cfMap = <String, String>{};
      final cfRaw = parsed['customFields'];
      if (cfRaw is Map) {
        cfRaw.forEach((k, v) {
          if (v == null) return;
          if (v is List) {
            cfMap[k.toString()] = v.join(', ');
          } else {
            cfMap[k.toString()] = v.toString();
          }
        });
      }

      double? price;
      final pRaw = parsed['suggestedPrice'];
      if (pRaw is num) {
        price = pRaw.toDouble();
      } else if (pRaw is String) {
        price = double.tryParse(pRaw.replaceAll(RegExp(r'[^0-9.]'), ''));
      }

      return AiGeneratedAd(
        title: parsed['title']?.toString(),
        description: parsed['description']?.toString(),
        suggestedCategoryId: parsed['categoryId']?.toString(),
        suggestedCategoryName: parsed['suggestedCategory']?.toString(),
        suggestedPrice: price,
        customFieldValues: cfMap,
      );
    } catch (e) {
      print('OpenAiService: error: $e');
      return null;
    }
  }
}
