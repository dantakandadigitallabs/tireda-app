import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:flutter/material.dart';

class NoConnectionScreen extends StatelessWidget {
  /// Called when the user taps Retry.
  /// Pass any async function — e.g. a controller's load method.
  final VoidCallback onRetry;

  /// Optional custom title. Defaults to "No Internet Connection".
  final String? title;

  /// Optional custom message.
  final String? message;

  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.primaryWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: AppThemeData.grey5,
                ),
                const SizedBox(height: 24),
                Text(
                  title ?? "No Internet Connection",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: FontFamily.bold,
                    color: AppThemeData.grey10,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      "Please check your network connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: FontFamily.regular,
                    color: AppThemeData.grey6,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: FontFamily.semiBold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}