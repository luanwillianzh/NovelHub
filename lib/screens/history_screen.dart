import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/novel_models.dart';
import '../services/novel_database_provider.dart';
import 'novel_detail_page.dart';
import 'chapter_detail_page.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
      ),
      body: Consumer<NovelDatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: dbProvider.getHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No reading history yet.\nStart reading novels to see them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final historyItems = snapshot.data!;

              return ListView.builder(
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  final novel = NovelSearchResult(
                    nome: item['name'],
                    url: item['novel_id'],
                    cover: item['cover'],
                  );
                  
                  final lastChapterId = item['last_chapter_id'] as String?;
                  final lastChapterTitle = item['last_chapter_title'] as String?;

                  return ListTile(
                    leading: novel.cover.isNotEmpty
                        ? Image.network(
                            novel.cover,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.book, size: 50),
                          )
                        : const Icon(Icons.book, size: 50),
                    title: Text(novel.nome),
                    subtitle: lastChapterTitle != null 
                        ? Text('Last read: $lastChapterTitle', 
                            style: const TextStyle(fontSize: 12))
                        : null,
                    onTap: () {
                      if (lastChapterId != null) {
                        // Navigate directly to the last read chapter
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChapterDetailPage(
                              novelInfo: novel,
                              chapterId: lastChapterId,
                            ),
                          ),
                        );
                      } else {
                        // Navigate to novel detail page if no specific chapter
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NovelDetailPage(
                              novelId: novel.url,
                            ),
                          ),
                        );
                      }
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'remove') {
                          dbProvider.removeFromHistory(novel.url);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'remove',
                          child: Text('Remove from History'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}