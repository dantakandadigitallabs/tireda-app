import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/html_screen_controller.dart';

class HtmlScreenView extends GetView<HtmlScreenController> {
  const HtmlScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, isBack: true, controller.title.value),
      body: Obx(() {
        final htmlContent = controller.content.value;

        if (htmlContent.isEmpty) {
          return Center(
            child: TextCustom(
              title: 'No content available'.tr,
              fontSize: 16,
              color: isDark ? AppThemeData.grey5 : AppThemeData.grey6,
            ),
          );
        }

        final bgColor = isDark ? '#1a1a1a' : '#ffffff';
        final textColor = isDark ? '#e0e0e0' : '#333333';

        final fullHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      background-color: $bgColor;
      color: $textColor;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 15px;
      line-height: 1.6;
      padding: 16px;
      margin: 0;
      word-wrap: break-word;
    }
    a { color: #3068FF; }
    img { max-width: 100%; height: auto; }
    h1, h2, h3 { color: $textColor; }
  </style>
</head>
<body>
$htmlContent
</body>
</html>
''';

        final webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(isDark ? AppThemeData.grey10 : AppThemeData.grey1)
          ..loadHtmlString(fullHtml);

        return WebViewWidget(controller: webViewController);
      }),
    );
  }
}
