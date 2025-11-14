// file: lib/services/internal_novel_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/novel_models.dart'; // Import your models

class NovelApiService {
  final Dio _dio;

  NovelApiService() : _dio = _createScraperDio();

  /// Creates a Dio client that ignores bad SSL certificates
  /// This replicates `rejectUnauthorized: false`
  static Dio _createScraperDio() {
    final dio = Dio();
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    return dio;
  }

  // --- Utility to get text or attr safely ---
  String _safeQueryText(dom.Element? element, [String? fallback = '']) =>
      (element?.text.trim()) ?? fallback ?? '';

  String _safeQueryAttr(dom.Element? element, String attr,
      [String? fallback = '']) =>
      element?.attributes[attr] ?? fallback ?? '';

  String _safeQueryHtml(dom.Element? element, [String? fallback = '']) =>
      (element?.innerHtml.trim()) ?? fallback ?? '';

  // --- Aggregator Methods (Public API) ---

  Future<List<NovelSearchResult>> searchAll(String text) async {
    // Since we added try-catch blocks inside the specific search methods,
    // Future.wait will complete successfully even if one source fails.
    final [central, illusia, mania] = await Future.wait([
      _centralSearch(text),
      _illusiaSearch(text),
      _maniaSearch(text),
    ]);

    return [...central, ...illusia, ...mania];
  }

  Future<NovelInfo> getNovelInfoAll(String novelId) async {
    final parts = novelId.split('-');
    final source = parts.first;
    final id = parts.sublist(1).join('-');

    switch (source) {
      case 'central':
        return _centralGetNovelInfo(id);
      case 'illusia':
        return _illusiaGetNovelInfo(id);
      case 'mania':
        return _maniaGetNovelInfo(id);
      default:
        throw Exception('Unknown novel source');
    }
  }

  Future<ChapterContent> getChapterAll(String novelId, String chapterId) async {
    final parts = novelId.split('-');
    final source = parts.first;
    final id = parts.sublist(1).join('-');

    final results = await Future.wait([
      (() async {
        switch (source) {
          case 'central':
            return _centralGetChapter(chapterId);
          case 'illusia':
            return _illusiaGetChapter(id, chapterId);
          case 'mania':
            return _maniaGetChapter(id, chapterId);
          default:
            throw Exception('Unknown novel source');
        }
      })(),
      getNovelInfoAll(novelId),
    ]);

    final chapterData = results[0] as ChapterContent;
    final novelInfo = results[1] as NovelInfo;

    final chapterList = novelInfo.chapters;
    final currentIndex = chapterList.indexWhere((ch) => ch[1] == chapterId);

    String? prevChapterId;
    String? nextChapterId;

    if (currentIndex > 0) {
      prevChapterId = chapterList[currentIndex - 1][1];
    }
    if (currentIndex >= 0 && currentIndex < chapterList.length - 1) {
      nextChapterId = chapterList[currentIndex + 1][1];
    }

    return ChapterContent(
      title: chapterData.title,
      subtitle: chapterData.subtitle,
      content: chapterData.content,
      prevChapterId: prevChapterId,
      nextChapterId: nextChapterId,
    );
  }

  Future<ChapterContent> getChapterContentOnly(
      String novelId, String chapterId) async {
    final parts = novelId.split('-');
    final source = parts.first;
    final id = parts.sublist(1).join('-');

    switch (source) {
      case 'central':
        return _centralGetChapter(chapterId);
      case 'illusia':
        return _illusiaGetChapter(id, chapterId);
      case 'mania':
        return _maniaGetChapter(id, chapterId);
      default:
        throw Exception('Unknown novel source for getChapterContentOnly');
    }
  }

  Future<List<NovelSearchResult>> lancamentosAll() async {
    final [central, illusia, mania] = await Future.wait([
      _centralSearch(""),
      _illusiaLancamentos(),
      _maniaLancamentos(),
    ]);
    return [...central, ...illusia, ...mania];
  }

  // ===== CentralNovel Port =====

  Future<NovelInfo> _centralGetNovelInfo(String novel) async {
    final url = 'https://centralnovel.com/series/$novel/';
    final response = await _dio.get(url);
    final $ = html_parser.parse(response.data);

    final name = _safeQueryText($.querySelector("h1[itemprop=name]"));
    final desc = _safeQueryText($.querySelector(".entry-content"));
    final cover = _safeQueryAttr($.querySelector("div.thumb img"), "src");

    final lista = $.querySelectorAll(".eplister a");

    final chapters = lista
        .asMap()
        .entries
        .where((entry) => entry.key % 2 == 0)
        .map((entry) => entry.value)
        .toList()
        .reversed
        .map((a) {
      final divs = a.querySelectorAll("div");
      final text = divs.take(2).map((d) => _safeQueryText(d)).join(" - ");
      final href = _safeQueryAttr(
        a,
        "href",
      ).split('/').lastWhere((s) => s.isNotEmpty);
      return [text, href];
    })
        .toList();

    final genres = $.querySelectorAll(".genxed a").map((a) {
      final href = _safeQueryAttr(
        a,
        "href",
      ).split('/').lastWhere((s) => s.isNotEmpty);
      return [href, _safeQueryText(a)];
    }).toList();

    return NovelInfo(
      nome: name,
      desc: desc,
      cover: cover,
      chapters: chapters,
      genres: genres,
    );
  }

  Future<ChapterContent> _centralGetChapter(String chapter) async {
    final url = 'https://centralnovel.com/$chapter/';
    final response = await _dio.get(url);
    final $ = html_parser.parse(response.data);

    final title = _safeQueryText($.querySelector("h1.entry-title"));
    final subtitle = _safeQueryText($.querySelector("div.cat-series"));
    final content = _safeQueryHtml(
      $.querySelector("div.epcontent.entry-content"),
    );

    return ChapterContent(title: title, subtitle: subtitle, content: content);
  }

  Future<List<NovelSearchResult>> _centralSearch(String text) async {
    try {
      const url = "https://centralnovel.com/wp-admin/admin-ajax.php";
      final data = {'action': 'ts_ac_do_search', 'ts_ac_query': text};

      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
          headers: {
            "Accept": "*/*",
            "Accept-Language": "pt-BR,pt;q=0.8,en-US;q=0.5,en;q=0.3",
          },
        ),
      );

      final Map<String, dynamic> dataMap;
      try {
        dataMap = jsonDecode(response.data) as Map<String, dynamic>;
      } catch (e) {
        return [];
      }

      final List<dynamic> seriesList = (dataMap['series'] as List<dynamic>?) ?? [];

      if (seriesList.isEmpty) {
        return [];
      }

      final Map<String, dynamic> seriesObject =
          (seriesList[0] as Map<String, dynamic>?) ?? {};

      final List<dynamic> lista = (seriesObject['all'] as List<dynamic>?) ?? [];

      return lista.map((a) {
        if (a is! Map<String, dynamic>) {
          return null;
        }

        final aMap = a;

        final postLink = aMap['post_link'] as String? ?? '';
        final postTitle = aMap['post_title'] as String? ?? 'Sem Título';
        final postImage = aMap['post_image'] as String? ?? '';

        if (postLink.isEmpty) {
          return null;
        }

        final urlParts = postLink.split('/');
        final urlSlug = urlParts.lastWhere((s) => s.isNotEmpty, orElse: () => '');

        if (urlSlug.isEmpty) {
          return null;
        }

        return NovelSearchResult(
          nome: postTitle,
          url: 'central-$urlSlug',
          cover: postImage,
        );
      }).whereType<NovelSearchResult>().toList();

    } catch (e) {
      print("Error in Central Search: $e");
      return [];
    }
  }

  // ===== Illusia API Port =====

  Future<List<NovelSearchResult>> _illusiaLancamentos() async {
    try {
      const url = "https://illusia.com.br/lancamentos/";
      final response = await _dio.get(url);
      final $ = html_parser.parse(response.data);

      return $.querySelectorAll("li._latest-updates").map((novel) {
        final a = novel.querySelector("a");
        final img = novel.querySelector("img");
        final urlSlug = _safeQueryAttr(
          a,
          "href",
        ).split('/').lastWhere((s) => s.isNotEmpty);
        return NovelSearchResult(
          url: 'illusia-$urlSlug',
          nome: _safeQueryAttr(a, "title"),
          cover: _safeQueryAttr(img, "src"),
        );
      }).toList();
    } catch (e) {
      print("Error in Illusia Lancamentos: $e");
      return [];
    }
  }

  Future<NovelInfo> _illusiaGetNovelInfo(String novel) async {
    final url = 'https://illusia.com.br/story/$novel/';
    final response = await _dio.get(url);
    final $ = html_parser.parse(response.data);

    final name = _safeQueryText(
      $.querySelector(".story__identity-title"),
    ).replaceAll("\n", " ");
    final desc = $
        .querySelectorAll("section.story__summary.content-section p")
        .map((p) => _safeQueryText(p))
        .join("\n");
    final cover = _safeQueryAttr(
      $.querySelector(".webfeedsFeaturedVisual"),
      "src",
    );

    final chapters = $.querySelectorAll(".chapter-group__list a").map((a) {
      final href = _safeQueryAttr(
        a,
        "href",
      ).split('/').lastWhere((s) => s.isNotEmpty);
      return [_safeQueryText(a), href];
    }).toList();

    final genres = $.querySelectorAll("._taxonomy-genre").map((a) {
      final href = _safeQueryAttr(
        a,
        "href",
      ).split('/').lastWhere((s) => s.isNotEmpty);
      return [href, _safeQueryText(a)];
    }).toList();

    return NovelInfo(
      nome: name,
      desc: desc,
      cover: cover,
      chapters: chapters,
      genres: genres,
    );
  }

  Future<ChapterContent> _illusiaGetChapter(
      String novel,
      String chapter,
      ) async {
    final url = 'https://illusia.com.br/story/$novel/$chapter/';
    final response = await _dio.get(url);
    final $ = html_parser.parse(response.data);

    final title = _safeQueryText(
      $.querySelector(".chapter__story-link"),
    ).replaceAll("\n", " ");
    final subtitle = _safeQueryText(
      $.querySelector(".chapter__title"),
    ).replaceAll("\n", " ");
    final content = _safeQueryHtml($.querySelector("#chapter-content"));

    return ChapterContent(title: title, subtitle: subtitle, content: content);
  }

  Future<List<NovelSearchResult>> _illusiaSearch(String text) async {
    try {
      final url =
          'https://illusia.com.br/?s=${Uri.encodeComponent(text)}&post_type=fcn_story';
      final response = await _dio.post(url);
      final $ = html_parser.parse(response.data);

      return $.querySelectorAll("li.card").map((a) {
        final link = a.querySelector("a");
        final img = a.querySelector("img");
        final urlSlug = _safeQueryAttr(
          link,
          "href",
        ).split('/').lastWhere((s) => s.isNotEmpty);
        return NovelSearchResult(
          nome: _safeQueryText(link),
          url: 'illusia-$urlSlug',
          cover: _safeQueryAttr(img, "src"),
        );
      }).toList();
    } catch (e) {
      print("Error in Illusia Search: $e");
      return [];
    }
  }

  // ===== Mania API Port =====

  Future<List<NovelSearchResult>> _maniaLancamentos() async {
    try {
      const url = "https://novelmania.com.br";
      final response = await _dio.get(url);
      final $ = html_parser.parse(response.data);

      return $.querySelectorAll(".novels .col-6").map((i) {
        final a = i.querySelector("a");
        final img = i.querySelector("img");
        final h2 = i.querySelector("h2");
        final urlSlug = _safeQueryAttr(
          a,
          "href",
        ).split('/').lastWhere((s) => s.isNotEmpty);
        return NovelSearchResult(
          url: 'mania-$urlSlug',
          nome: _safeQueryText(h2),
          cover: _safeQueryAttr(img, "src"),
        );
      }).toList();
    } catch (e) {
      print("Error in Mania Lancamentos: $e");
      return [];
    }
  }

  Future<NovelInfo> _maniaGetNovelInfo(String novel) async {
    final url = 'https://novelmania.com.br/novels/$novel/';
    final response = await _dio.get(url);
    final $ = html_parser.parse(response.data);

    final name = _safeQueryText(
      $.querySelector("h1.font-400.mb-2.wow.fadeInRight.mr-3"),
    );
    final desc = $
        .querySelectorAll("div.text p")
        .map((p) => _safeQueryText(p))
        .join("\n");
    final cover = _safeQueryAttr($.querySelector(".img-responsive"), "src");

    final chapters = $.querySelectorAll("ol.list-inline li a").map((a) {
      final href = _safeQueryAttr(
        a,
        "href",
      ).split('/').lastWhere((s) => s.isNotEmpty);
      return [_safeQueryText(a.querySelector("strong")), href];
    }).toList();

    final genres = $.querySelectorAll(".list-tags a").map((a) {
      final href = _safeQueryAttr(
        a,
        "href",
      ).split('/').lastWhere((s) => s.isNotEmpty);
      return [href, _safeQueryAttr(a, "title")];
    }).toList();

    return NovelInfo(
      nome: name,
      desc: desc,
      cover: cover,
      chapters: chapters,
      genres: genres,
    );
  }

  Future<ChapterContent> _maniaGetChapter(String novel, String chapter) async {
    final url = 'https://novelmania.com.br/novels/$novel/capitulos/$chapter';
    final response = await _dio.get(url);
    final $ = html_parser.parse(response.data);

    final title = _safeQueryText($.querySelector("h3.mb-0"));
    final subtitle = _safeQueryText($.querySelector("h2.mt-0"));
    final content = _safeQueryHtml($.querySelector("#chapter-content"));

    return ChapterContent(title: title, subtitle: subtitle, content: content);
  }

  Future<List<NovelSearchResult>> _maniaSearch(String text) async {
    try {
      final url =
          'https://novelmania.com.br/novels?titulo=${Uri.encodeComponent(text)}';
      final response = await _dio.get(url);
      final $ = html_parser.parse(response.data);

      return $.querySelectorAll(".top-novels").map((a) {
        final link = a.querySelector("a");
        final h5 = a.querySelector("h5");
        final img = a.querySelector("img");
        final urlSlug = _safeQueryAttr(
          link,
          "href",
        ).split('/').lastWhere((s) => s.isNotEmpty);
        return NovelSearchResult(
          nome: _safeQueryText(h5),
          url: 'mania-$urlSlug',
          cover: _safeQueryAttr(img, "src"),
        );
      }).toList();
    } catch (e) {
      print("Error in Mania Search: $e");
      return [];
    }
  }
}