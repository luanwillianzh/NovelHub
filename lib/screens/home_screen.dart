import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/novel_models.dart';
import '../services/novel_api_service.dart';
import '../services/novel_database_provider.dart';
import 'novel_detail_page.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NovelApiService _apiService = NovelApiService();
  final TextEditingController _searchController = TextEditingController();

  // This one Future will hold whatever we want to display:
  // EITHER the releases OR the search results.
  late Future<List<NovelSearchResult>> _displayFuture;

  @override
  void initState() {
    super.initState();
    // Load the releases when the app first starts
    _loadReleases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Sets the display future to load all releases
  void _loadReleases() {
    setState(() {
      _displayFuture = _apiService.lancamentosAll();
    });
  }

  /// Sets the display future to a new search query
  void _performSearch(String query) {
    if (query.isEmpty) {
      _loadReleases(); // If search is empty, just show releases
      return;
    }
    
    // Set the future to the search result.
    // The FutureBuilder will automatically update.
    setState(() {
      _displayFuture = _apiService.searchAll(query);
    });
  }

  /// Clears the search bar and returns to the releases
  void _clearSearch() {
    _searchController.clear();
    _loadReleases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // We'll use the title property for our search bar
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search novels...',
            // Removes the underline
            border: InputBorder.none, 
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch, // Calls our clear method
            ),
          ),
          // This triggers the search when the user hits 'enter'
          onSubmitted: (query) => _performSearch(query), 
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            tooltip: 'Reading History',
          ),
        ],
      ),
      // This FutureBuilder is the same as before.
      // It just points to _displayFuture, which we can change.
      body: FutureBuilder<List<NovelSearchResult>>(
        future: _displayFuture,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // Show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show the list of novels
          final novels = snapshot.data;
          if (novels == null || novels.isEmpty) {
            return const Center(
              child: Text('No novels found.'),
            );
          }

          return ListView.builder(
            itemCount: novels.length,
            itemBuilder: (context, index) {
              final novel = novels[index];
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
                  // This is where you would navigate to a detail screen
                  /* print('Tapped on: ${novel.url}'); */
                },
              );
            },
          );
        },
      ),
    );
  }
}