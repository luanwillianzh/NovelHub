// file: lib/models/novel_models.dart

import 'package:flutter/foundation.dart';

/// Represents a single novel in a search list or "lancamentos" list.
@immutable
class NovelSearchResult {
  final String nome;
  final String url; // This is the unique ID, e.g., "central-novel-slug"
  final String cover;

  const NovelSearchResult({
    required this.nome,
    required this.url,
    required this.cover,
  });

  factory NovelSearchResult.fromJson(Map<String, dynamic> json) {
    return NovelSearchResult(
      nome: json['nome'] as String? ?? '',
      url: json['url'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
    );
  }
}

/// Represents the detailed information for a single novel.
@immutable
class NovelInfo {
  final String nome;
  final String desc;
  final String cover;
  // A list where each item is [chapterName, chapterId]
  final List<List<String>> chapters;
  // A list where each item is [genreId, genreName]
  final List<List<String>> genres;

  const NovelInfo({
    required this.nome,
    required this.desc,
    required this.cover,
    required this.chapters,
    required this.genres,
  });

  factory NovelInfo.fromJson(Map<String, dynamic> json) {
    // Safely parse the nested lists
    final List<List<String>> parsedChapters =
        (json['chapters'] as List<dynamic>?)
                ?.map((item) => (item as List<dynamic>)
                    .map((s) => s.toString())
                    .toList())
                .toList() ??
            <List<String>>[];

    final List<List<String>> parsedGenres =
        (json['genres'] as List<dynamic>?)
                ?.map((item) => (item as List<dynamic>)
                    .map((s) => s.toString())
                    .toList())
                .toList() ??
            <List<String>>[];

    return NovelInfo(
      nome: json['nome'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      chapters: parsedChapters,
      genres: parsedGenres,
    );
  }
}

/// Represents the content of a single chapter.
@immutable
class ChapterContent {
  final String title;
  final String subtitle;
  final String content; // This is raw HTML
  final String? prevChapterId;
  final String? nextChapterId;

  const ChapterContent({
    required this.title,
    required this.subtitle,
    required this.content,
    this.prevChapterId,
    this.nextChapterId,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      content: json['content'] as String? ?? '',
      prevChapterId: json['prevChapterId'] as String?, // Can be null
      nextChapterId: json['nextChapterId'] as String?, // Can be null
    );
  }
}