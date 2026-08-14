import 'package:eSellify/app/services/localization_service.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// One localized text field bound to a `defaultController` plus one
/// `TextEditingController` per supported language code.
///
/// The `LocalizationTabSection` below hosts one or more of these so the
/// same tab strip can drive several fields (title + description) — the
/// selected tab decides which language's controller each field renders.
class LocalizationField {
  final String fieldLabel;
  final TextEditingController defaultController;
  final Map<String, TextEditingController> byLanguage;
  final String defaultHint;
  final String languageHint;

  /// >1 renders a multi-line text area (e.g. Description).
  final int? maxLines;

  const LocalizationField({
    required this.fieldLabel,
    required this.defaultController,
    required this.byLanguage,
    this.defaultHint = 'Enter value',
    this.languageHint = 'Translate here',
    this.maxLines,
  });
}

/// Language tab strip + per-language text inputs — customer-app port of
/// the admin panel's `LocalizationTabSection`. The tab list is sourced
/// from [LocalizationService.locales] so users can add a translation
/// for every language the app itself supports.
///
/// Defaults on tab 0 ("Default"). Any language tab whose text is left
/// blank is dropped at save time (see the controller).
class LocalizationTabSection extends StatelessWidget {
  final RxInt selectedLanguageIndex;
  final List<LocalizationField> fields;

  const LocalizationTabSection({
    super.key,
    required this.selectedLanguageIndex,
    required this.fields,
  });

  /// Tab codes come from the admin's ACTIVE languages (not the full list of
  /// locales the app ships) — loaded lazily, tabs appear once fetched.
  List<String> get _codes => LocalizationService.activeLanguageCodes.toList();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();
    LocalizationService.ensureActiveCodesLoaded();
    return Obx(() {
      final codes = _codes;
      final selected = selectedLanguageIndex.value.clamp(0, codes.length);
      final isDefault = selected == 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey9.withValues(alpha: 0.35) : AppThemeData.grey1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab(
                    label: 'Default'.tr,
                    code: null,
                    isSelected: isDefault,
                    isDark: isDark,
                    onTap: () => selectedLanguageIndex.value = 0,
                  ),
                  for (int i = 0; i < codes.length; i++)
                    _buildTab(
                      label: LocalizationService.languageNames[codes[i]] ?? codes[i].toUpperCase(),
                      code: codes[i].toUpperCase(),
                      isSelected: selected == i + 1,
                      isDark: isDark,
                      onTap: () => selectedLanguageIndex.value = i + 1,
                    ),
                ],
              ),
            ),
            for (int f = 0; f < fields.length; f++) ...[
              const SizedBox(height: 14),
              _buildFieldInput(fields[f], isDefault, selected, isDark, codes),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTab({
    required String label,
    required String? code,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final display = code != null && code.isNotEmpty ? "$label ($code)" : label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemeData.primary4
              : (isDark ? AppThemeData.grey8 : AppThemeData.grey2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppThemeData.primary4
                : (isDark ? AppThemeData.grey8 : AppThemeData.grey3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              code == null ? Icons.language_rounded : Icons.translate_rounded,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppThemeData.grey5 : AppThemeData.grey6),
            ),
            const SizedBox(width: 6),
            TextCustom(
              title: display,
              fontSize: 12,
              fontFamily: isSelected ? FontFamily.bold : FontFamily.medium,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppThemeData.grey3 : AppThemeData.grey8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldInput(
    LocalizationField field,
    bool isDefault,
    int selected,
    bool isDark,
    List<String> codes,
  ) {
    late final TextEditingController controller;
    late final String label;
    late final String hint;
    if (isDefault) {
      controller = field.defaultController;
      label = field.fieldLabel;
      hint = field.defaultHint;
    } else {
      final code = codes[selected - 1];
      controller = field.byLanguage.putIfAbsent(code, TextEditingController.new);
      label = "${field.fieldLabel} (${code.toUpperCase()})";
      final defText = field.defaultController.text;
      hint = defText.isNotEmpty ? defText : field.languageHint;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: TextCustom(
            title: label,
            fontSize: 13,
            fontFamily: FontFamily.semiBold,
            color: isDark ? AppThemeData.grey3 : AppThemeData.grey8,
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: field.maxLines ?? 1,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: AppThemeData.primary4,
          style: TextStyle(
            color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
            fontFamily: FontFamily.regular,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
              fontFamily: FontFamily.regular,
              fontSize: 13,
            ),
            filled: true,
            fillColor: isDark ? AppThemeData.grey10 : AppThemeData.primaryWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppThemeData.grey8 : AppThemeData.grey3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppThemeData.primary4, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
