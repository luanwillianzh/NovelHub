import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/novel_models.dart';
import '../services/novel_database_provider.dart';
import 'novel_detail_page.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Consumer<NovelDatabaseProvider>(
        builder: (context, dbProvider, child) {
          return FutureBuilder<List<NovelSearchResult>>(
            future: dbProvider.getFavorites(),
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
                    'No favorites yet.\nAdd novels to your favorites from their detail pages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final favorites = snapshot.data!;

              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final novel = favorites[index];
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelDetailPage(
                            novelId: novel.url,
                          ),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await dbProvider.toggleFavorite(novel);
                      },
                      tooltip: 'Remove from favorites',
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