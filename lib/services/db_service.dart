import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/drama.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kdrama_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tracked_dramas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tmdbId INTEGER UNIQUE,
            title TEXT,
            posterPath TEXT,
            status TEXT,
            totalEpisodes INTEGER DEFAULT 0,
            watchedEpisodes INTEGER DEFAULT 0,
            addedDate TEXT
          )
        ''');
      },
    );
  }

  Future<void> addOrUpdate(TrackedDrama drama) async {
    final db = await database;
    await db.insert(
      'tracked_dramas',
      drama.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStatus(int tmdbId, String status) async {
    final db = await database;
    await db.update(
      'tracked_dramas',
      {'status': status},
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
    );
  }

  Future<void> updateProgress(int tmdbId, int watchedEpisodes) async {
    final db = await database;
    await db.update(
      'tracked_dramas',
      {'watchedEpisodes': watchedEpisodes},
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
    );
  }

  Future<void> remove(int tmdbId) async {
    final db = await database;
    await db.delete(
      'tracked_dramas',
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
    );
  }

  Future<List<TrackedDrama>> getAll() async {
    final db = await database;
    final maps = await db.query('tracked_dramas', orderBy: 'addedDate DESC');
    return maps.map((m) => TrackedDrama.fromMap(m)).toList();
  }

  Future<List<TrackedDrama>> getByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'tracked_dramas',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'addedDate DESC',
    );
    return maps.map((m) => TrackedDrama.fromMap(m)).toList();
  }

  Future<TrackedDrama?> getByTmdbId(int tmdbId) async {
    final db = await database;
    final maps = await db.query(
      'tracked_dramas',
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
    );
    if (maps.isEmpty) return null;
    return TrackedDrama.fromMap(maps.first);
  }
}
