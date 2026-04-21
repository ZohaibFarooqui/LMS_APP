import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../database/location_track_db.dart';
import '../network/dio_client.dart';

const kIsTrackingKey = 'lms_is_tracking';
const kTrackingCardKey = 'lms_tracking_card_no';
const _locationTaskName = 'lms_hourly_location';
const _notificationId = 9001;
const _channelId = 'lms_tracking_channel';

class LocationTrackingService {
  LocationTrackingService()
      : _db = LocationTrackDb(),
        _dio = DioClient.instance,
        _notifications = FlutterLocalNotificationsPlugin();

  final LocationTrackDb _db;
  final Dio _dio;
  final FlutterLocalNotificationsPlugin _notifications;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            'Work Session Tracking',
            description:
                'Shown while your work session is active and location is being tracked.',
            importance: Importance.low,
          ));
    }

    // Auto-sync unsynced records whenever connectivity is restored
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _syncIfTracking();
    });
  }

  Future<void> startTracking(String cardNo) async {
    // Ensure background location permission is granted
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      await Geolocator.requestPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kIsTrackingKey, true);
    await prefs.setString(kTrackingCardKey, cardNo);

    await Workmanager().registerPeriodicTask(
      _locationTaskName,
      _locationTaskName,
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.not_required),
    );

    if (Platform.isAndroid) await _showTrackingNotification();

    debugPrint('[LocationTracking] Started for $cardNo');
  }

  Future<void> stopTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final cardNo = prefs.getString(kTrackingCardKey) ?? '';

    await prefs.setBool(kIsTrackingKey, false);
    await Workmanager().cancelByUniqueName(_locationTaskName);
    await _notifications.cancel(_notificationId);

    if (cardNo.isNotEmpty) await syncPendingLocations(cardNo);

    debugPrint('[LocationTracking] Stopped');
  }

  Future<bool> get isTracking async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kIsTrackingKey) ?? false;
  }

  Future<void> syncPendingLocations(String cardNo) async {
    try {
      final pending = await _db.getUnsynced(cardNo);
      if (pending.isEmpty) return;

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/location/batch',
        data: {
          'card_no': cardNo,
          'locations': pending
              .map((r) => {
                    'latitude': r['latitude'],
                    'longitude': r['longitude'],
                    'accuracy': r['accuracy'],
                    'recorded_at': r['recorded_at'],
                  })
              .toList(),
        },
      );

      if (response.statusCode == 200) {
        final ids = pending.map((r) => r['id'] as int).toList();
        await _db.markSynced(ids);
        await _db.pruneOldSynced();
        debugPrint('[LocationTracking] Synced ${ids.length} records');
      }
    } catch (e) {
      debugPrint('[LocationTracking] Sync failed (will retry): $e');
    }
  }

  Future<void> _syncIfTracking() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(kIsTrackingKey) ?? false)) return;
    final cardNo = prefs.getString(kTrackingCardKey) ?? '';
    if (cardNo.isNotEmpty) await syncPendingLocations(cardNo);
  }

  Future<void> _showTrackingNotification() async {
    const details = AndroidNotificationDetails(
      _channelId,
      'Work Session Active',
      channelDescription:
          'Your work session is active. Location is being tracked hourly.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );
    await _notifications.show(
      _notificationId,
      'Work Session Active',
      'LMS is tracking your work location. Tap to open.',
      const NotificationDetails(android: details),
    );
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
