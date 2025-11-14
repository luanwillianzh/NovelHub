// file: lib/screens/chapter_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/novel_models.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../services/novel_api_service.dart';
import '../services/novel_database_provider.dart';
import 'package:provider/provider.dart';

class ChapterDetailPage extends StatefulWidget {
  final NovelSearchResult novelInfo;
  final String chapterId;

  const ChapterDetailPage({
    super.key,
    required this.novelInfo,
    required this.chapterId,
  });

  @override
  State<ChapterDetailPage> createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  final NovelApiService _apiService = NovelApiService();
  late Future<ChapterContent> _chapterFuture;
  late NovelDatabaseProvider _dbProvider;

  @override
  void initState() {
    super.initState();
    // Fetch the chapter content when the widget is initialized
    _chapterFuture =
        _apiService.getChapterAll(widget.novelInfo.url, widget.chapterId);
  }

  /// Navigates to a different chapter, replacing the current screen
  void _navigateToChapter(String newChapterId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // Create a new instance of the screen
        builder: (context) => ChapterDetailPage(
          novelInfo: widget.novelInfo,
          chapterId: newChapterId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _dbProvider = Provider.of<NovelDatabaseProvider>(context);
    return Scaffold(
      appBar: AppBar(
        // The FutureBuilder will update this title once data is loaded
        title: FutureBuilder<ChapterContent>(
          future: _chapterFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              // Use the chapter's subtitle (or title if subtitle is empty)
              final subtitle = snapshot.data!.subtitle;
              return Text(
                subtitle.isNotEmpty ? subtitle : snapshot.data!.title,
                style: const TextStyle(fontSize: 16),
              );
            }
            return const Text('Loading...');
          },
        ),
      ),
      body: FutureBuilder<ChapterContent>(
        future: _chapterFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Chapter not found.'));
          }

          final chapter = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _addToHistory(chapter);
          });

          // We use a CustomScrollView to combine scrollable content
          // with a bottom navigation bar that doesn't move.
          return Column(
            children: [
              Expanded(
                // This makes the content area scrollable
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter Title
                      Text(
                        chapter.title.replaceAll("\n", ""),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      // Chapter Subtitle (if it exists)
                      if (chapter.subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(
                            chapter.subtitle.replaceAll("\n", ""),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      const Divider(height: 32),

                      // --- RENDER THE HTML CONTENT ---
                      Consumer<SettingsModel>(
                        builder: (context, settingsModel, child) {
                          return HtmlWidget(
                            chapter.content, // Add indentation spaces
                            textStyle: TextStyle(
                              fontSize: settingsModel.fontSize,
                              height: 1.5,
                              textBaseline: TextBaseline.alphabetic,
                            ),
                            // Custom styling for paragraph elements to add indentation and justification
                            customStylesBuilder: (element) {
                              if (element.localName == 'p') {
                                return {'text-align': 'justify'};
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- Bottom Navigation Bar ---
              _buildChapterNavigation(chapter),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addToHistory(ChapterContent chapter) async {
    try {
      // Use the chapter title as the display title for history
      String displayTitle = chapter.title;
      if (chapter.subtitle.isNotEmpty && chapter.subtitle != chapter.title) {
        displayTitle = "${chapter.title} - ${chapter.subtitle}";
      } else if (chapter.subtitle.isNotEmpty) {
        displayTitle = chapter.subtitle;
      }

      await _dbProvider.addToHistory(
        widget.novelInfo,
        lastChapterId: widget.chapterId,
        lastChapterTitle: displayTitle,
      );
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  /// Builds the "Previous" and "Next" buttons at the bottom
  Widget _buildChapterNavigation(ChapterContent chapter) {
    bool hasPrev = chapter.prevChapterId != null;
    bool hasNext = chapter.nextChapterId != null;

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Chapter Button
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            // Disable button if there is no previous chapter
            onPressed: hasPrev
                ? () => _navigateToChapter(chapter.prevChapterId!)
                : null,
          ),

          // Next Chapter Button
          TextButton.icon(
            label: const Text('Next'),
            icon: const Icon(Icons.arrow_forward),
            // Disable button if there is no next chapter
            onPressed: hasNext
                ? () => _navigateToChapter(chapter.nextChapterId!)
                : null,
          ),
        ],
      ),
    );
  }
}