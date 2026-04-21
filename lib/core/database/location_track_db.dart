import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocationTrackDb {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lms_location_tracks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE location_tracks (
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

  Future<void> insert({
    required String cardNo,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final db = await database;
    await db.insert('location_tracks', {
      'card_no': cardNo,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'recorded_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String cardNo) async {
    final db = await database;
    return db.query(
      'location_tracks',
      where: 'card_no = ? AND synced = 0',
      whereArgs: [cardNo],
      orderBy: 'recorded_at ASC',
      limit: 100,
    );
  }

  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    await db.update(
      'location_tracks',
      {'synced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<void> pruneOldSynced() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    await db.delete(
      'location_tracks',
      where: 'synced = 1 AND recorded_at < ?',
      whereArgs: [cutoff],
    );
  }
}
