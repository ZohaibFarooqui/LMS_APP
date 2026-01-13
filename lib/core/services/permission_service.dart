import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
///
/// This service handles:
/// - Checking permission status
/// - Requesting permissions
/// - Showing rationale dialogs
class PermissionService {
  /// Request all required app permissions
  Future<PermissionResults> requestAllPermissions() async {
    final results = PermissionResults();

    // Request location permission
    results.location = await _requestLocationPermission();

    // Request notification permission (Android 13+)
    results.notification = await _requestNotificationPermission();

    return results;
  }

  /// Request location permission
  Future<PermissionStatus> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    
    return status;
  }

  /// Request notification permission (Android 13+)
  Future<PermissionStatus> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    
    return status;
  }

  /// Check if location permission is granted
  Future<bool> isLocationGranted() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Show permission rationale dialog
  static Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String settingsButtonText,
    String cancelButtonText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelButtonText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(settingsButtonText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Results of permission requests
class PermissionResults {
  PermissionStatus location = PermissionStatus.denied;
  PermissionStatus notification = PermissionStatus.denied;

  bool get allGranted =>
      location.isGranted && notification.isGranted;

  bool get locationGranted => location.isGranted;
  bool get notificationGranted => notification.isGranted;
}









