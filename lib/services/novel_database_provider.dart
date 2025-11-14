import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../models/novel_models.dart';

class NovelDatabaseProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  // Favorites
  bool _isNovelFavorite = false;
  bool get isNovelFavorite => _isNovelFavorite;
  
  // History
  bool _isNovelInHistory = false;
  bool get isNovelInHistory => _isNovelInHistory;
  
  Map<String, dynamic>? _historyItem;
  Map<String, dynamic>? get historyItem => _historyItem;

  Future<void> checkIfFavorite(String novelId) async {
    _isNovelFavorite = await _dbService.isFavorite(novelId);
    notifyListeners();
  }

  Future<void> toggleFavorite(NovelSearchResult novel) async {
    if (_isNovelFavorite) {
      await _dbService.removeFavorite(novel.url);
      _isNovelFavorite = false;
    } else {
      await _dbService.addFavorite(novel);
      _isNovelFavorite = true;
    }
    notifyListeners();
  }

  Future<void> checkIfInHistory(String novelId) async {
    _isNovelInHistory = await _dbService.isInHistory(novelId);
    if (_isNovelInHistory) {
      _historyItem = await _dbService.getHistoryItem(novelId);
    } else {
      _historyItem = null;
    }
    notifyListeners();
  }

  Future<void> addToHistory(NovelSearchResult novel, {String? lastChapterId, String? lastChapterTitle}) async {
    await _dbService.addToHistory(novel, lastChapterId: lastChapterId, lastChapterTitle: lastChapterTitle);
    _isNovelInHistory = true;
    _historyItem = await _dbService.getHistoryItem(novel.url);
    notifyListeners();
  }

  Future<void> updateHistoryChapter(String novelId, String chapterId, String chapterTitle) async {
    await _dbService.updateHistoryChapter(novelId, chapterId, chapterTitle);
    _historyItem = await _dbService.getHistoryItem(novelId);
    notifyListeners();
  }

  Future<List<NovelSearchResult>> getFavorites() async {
    return await _dbService.getFavorites();
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    return await _dbService.getHistory();
  }

  Future<int> removeFromHistory(String novelId) async {
    final result = await _dbService.removeFromHistory(novelId);
    if (novelId == _historyItem?['novel_id']) {
      _isNovelInHistory = false;
      _historyItem = null;
    }
    notifyListeners();
    return result;
  }
}