import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

const kLocationTaskName = 'lms_hourly_location';
const kIsTrackingKey = 'lms_is_tracking';
const kTrackingCardKey = 'lms_tracking_card_no';
// const _apiBase = 'http://apps.d-tech.com.pk:8001';
const _apiBase = 'http://163.61.91.221:8001';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName != kLocationTaskName) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(kIsTrackingKey) ?? false)) return true;
      final cardNo = prefs.getString(kTrackingCardKey) ?? '';
      if (cardNo.isEmpty) return true;

      // Check and request location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationTask] Permission denied: $permission — skipping');
        return true;
      }

      // Capture location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      // Persist to SQLite
      final db = await _openDb();
      await db.insert('location_tracks', {
        'card_no': cardNo,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
        'synced': 0,
      });
      debugPrint('[LocationTask] Saved lat=${position.latitude} lng=${position.longitude} for $cardNo');

      // Opportunistic sync (failure is fine — will retry next interval)
      await _trySyncFromDb(db, cardNo);

      await db.close();
    } catch (e, st) {
      debugPrint('[LocationTask] Error: $e\n$st');
      // Return true so WorkManager doesn't retry immediately
    }

    return true;
  });
}

Future<Database> _openDb() async {
  final path = join(await getDatabasesPath(), 'lms_location_tracks.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, _) => db.execute('''
      CREATE TABLE IF NOT EXISTS location_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_no TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL DEFAULT 0,
        recorded_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    '''),
  );
}

Future<void> _trySyncFromDb(Database db, String cardNo) async {
  try {
    final rows = await db.query(
      'location_tracks',
      where: 'card_no = ? AND synced = 0',
      whereArgs: [cardNo],
      limit: 50,
    );
    if (rows.isEmpty) return;

    final dio = Dio(BaseOptions(
      baseUrl: _apiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final response = await dio.post<Map<String, dynamic>>(
      '/auth/location/batch',
      data: {
        'card_no': cardNo,
        'locations': rows
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
      final ids = rows.map((r) => r['id'] as int).toList();
      await db.update(
        'location_tracks',
        {'synced': 1},
        where: 'id IN (${ids.map((_) => '?').join(',')})',
        whereArgs: ids,
      );
    }
  } catch (_) {
    // Network unavailable — leave unsynced, will retry
  }
}
