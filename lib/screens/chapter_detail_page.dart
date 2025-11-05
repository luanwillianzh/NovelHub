// file: lib/screens/chapter_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/novel_models.dart';
import '../services/novel_api_service.dart';

class ChapterDetailPage extends StatefulWidget {
  final String novelId;
  final String chapterId;

  const ChapterDetailPage({
    super.key,
    required this.novelId,
    required this.chapterId,
  });

  @override
  State<ChapterDetailPage> createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  final NovelApiService _apiService = NovelApiService();
  late Future<ChapterContent> _chapterFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the chapter content when the widget is initialized
    _chapterFuture =
        _apiService.getChapterAll(widget.novelId, widget.chapterId);
  }

  /// Navigates to a different chapter, replacing the current screen
  void _navigateToChapter(String newChapterId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // Create a new instance of the screen
        builder: (context) => ChapterDetailPage(
          novelId: widget.novelId,
          chapterId: newChapterId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        chapter.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      // Chapter Subtitle (if it exists)
                      if (chapter.subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(
                            chapter.subtitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      const Divider(height: 32),
                      
                      // --- RENDER THE HTML CONTENT ---
                      HtmlWidget(
                        chapter.content,
                        textStyle: const TextStyle(fontSize: 16, height: 1.5),
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