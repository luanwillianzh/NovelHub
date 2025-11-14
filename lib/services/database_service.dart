import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/novel_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'novelhub.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        novel_id TEXT UNIQUE,
        name TEXT,
        cover TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create history table
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        novel_id TEXT,
        name TEXT,
        cover TEXT,
        last_chapter_id TEXT,
        last_chapter_title TEXT,
        last_read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Favorites methods
  Future<int> addFavorite(NovelSearchResult novel) async {
    final db = await database;
    try {
      return await db.insert(
        'favorites',
        {
          'novel_id': novel.url,
          'name': novel.nome,
          'cover': novel.cover,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }

  Future<int> removeFavorite(String novelId) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
  }

  Future<bool> isFavorite(String novelId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
    return result.isNotEmpty;
  }

  Future<List<NovelSearchResult>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return NovelSearchResult(
        nome: maps[i]['name'],
        url: maps[i]['novel_id'],
        cover: maps[i]['cover'],
      );
    });
  }

  // History methods
  Future<int> addToHistory(NovelSearchResult novel, {String? lastChapterId, String? lastChapterTitle}) async {
    final db = await database;
    try {
      // Check if novel already exists in history
      final existing = await db.query(
        'history',
        where: 'novel_id = ?',
        whereArgs: [novel.url],
      );

      if (existing.isNotEmpty) {
        // Update existing record
        return await db.update(
          'history',
          {
            'name': novel.nome,
            'cover': novel.cover,
            'last_chapter_id': lastChapterId ?? existing[0]['last_chapter_id'],
            'last_chapter_title': lastChapterTitle ?? existing[0]['last_chapter_title'],
            'last_read_at': DateTime.now().toIso8601String(),
          },
          where: 'novel_id = ?',
          whereArgs: [novel.url],
        );
      } else {
        // Insert new record
        return await db.insert(
          'history',
          {
            'novel_id': novel.url,
            'name': novel.nome,
            'cover': novel.cover,
            'last_chapter_id': lastChapterId,
            'last_chapter_title': lastChapterTitle,
            'last_read_at': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('Error adding to history: $e');
      rethrow;
    }
  }

  Future<int> updateHistoryChapter(String novelId, String chapterId, String chapterTitle) async {
    final db = await database;
    return await db.update(
      'history',
      {
        'last_chapter_id': chapterId,
        'last_chapter_title': chapterTitle,
        'last_read_at': DateTime.now().toIso8601String(),
      },
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
  }

  Future<bool> isInHistory(String novelId) async {
    final db = await database;
    final result = await db.query(
      'history',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getHistoryItem(String novelId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'history',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'last_read_at DESC',
    );

    return maps;
  }

  Future<int> removeFromHistory(String novelId) async {
    final db = await database;
    return await db.delete(
      'history',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}