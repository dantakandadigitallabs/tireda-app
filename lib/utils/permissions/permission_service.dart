import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tireda Custom: Centralized permission handling.
///
/// Every part of the app that needs a runtime permission (location, camera,
/// media/storage, notifications) should call through this service instead of
/// talking to `permission_handler` directly. This keeps rationale dialogs,
/// denial handling, and Play Store "contextual justification" consistent
/// across the whole app.
class PermissionService {
  PermissionService._();

  /// Request location permission (foreground only).
  /// Use this before showing "ads near me" / distance-based features.
  static Future<bool> requestLocation() {
    return _requestPermission(
      permission: Permission.locationWhenInUse,
      title: 'Location Access',
      message:
      'Tireda uses your location to show ads near you and calculate '
          'distance to sellers. This is only used while the app is open.',
    );
  }

  /// Request camera permission.
  /// Use this before opening the camera to take a photo for an ad listing.
  static Future<bool> requestCamera() {
    return _requestPermission(
      permission: Permission.camera,
      title: 'Camera Access',
      message: 'Tireda needs camera access so you can take photos for your ad listings.',
    );
  }

  /// Request photo/media library permission.
  /// Use this before opening the gallery picker to attach images to an ad.
  static Future<bool> requestPhotos() {
    return _requestPermission(
      permission: Permission.photos,
      title: 'Photo Access',
      message: 'Tireda needs access to your photos so you can attach images to your ad listings.',
    );
  }

  /// Request notification permission (Android 13+ requires this explicitly).
  static Future<bool> requestNotifications() {
    return _requestPermission(
      permission: Permission.notification,
      title: 'Notifications',
      message: 'Tireda sends you notifications for messages, offers, and updates on your ads.',
    );
  }

  /// Core flow shared by every permission type:
  /// 1. If already granted -> return true immediately, no dialog.
  /// 2. If not yet requested / denied -> show an in-app rationale dialog
  ///    first, THEN trigger the native OS prompt.
  /// 3. If permanently denied -> show a dialog directing the user to
  ///    app settings (native prompt won't show again in this case).
  static Future<bool> _requestPermission({
    required Permission permission,
    required String title,
    required String message,
  }) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(title: title, message: message);
      return false;
    }

    // Show contextual rationale before the native OS dialog.
    final shouldProceed = await _showRationaleDialog(title: title, message: message);
    if (!shouldProceed) {
      return false;
    }

    final result = await permission.request();
    return result.isGranted;
  }

  static Future<bool> _showRationaleDialog({
    required String title,
    required String message,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  static Future<void> _showSettingsDialog({
    required String title,
    required String message,
  }) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(title),
        content: Text(
          '$message\n\nYou\'ve previously denied this permission. Please enable it from app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}