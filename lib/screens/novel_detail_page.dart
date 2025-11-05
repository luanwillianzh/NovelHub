// file: lib/screens/novel_detail_page.dart

import 'package:flutter/material.dart';
import '../models/novel_models.dart';
import '../services/novel_api_service.dart';
import 'chapter_detail_page.dart';
import 'epub_downloader_page.dart';

class NovelDetailPage extends StatefulWidget {
  final String novelId;

  const NovelDetailPage({super.key, required this.novelId});

  @override
  State<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends State<NovelDetailPage> {
  final NovelApiService _apiService = NovelApiService();
  late Future<NovelInfo> _novelInfoFuture;

  bool _chaptersReversed = false;

  @override
  void initState() {
    super.initState();
    _novelInfoFuture = _apiService.getNovelInfoAll(widget.novelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<NovelInfo>(
        future: _novelInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Novel not found.'));
          }

          final novel = snapshot.data!;

          return CustomScrollView(
            slivers: [_buildSliverAppBar(novel), _buildNovelDetails(novel)],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(NovelInfo novel) {
    return SliverAppBar(
      expandedHeight: 350.0,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Download EPUB',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EpubDownloadPage(novelInfo: novel, novelId: widget.novelId),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          novel.nome,
          textAlign: TextAlign.center,
          style: const TextStyle(
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        background: novel.cover.isNotEmpty
            ? Image.network(
                novel.cover,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.book, size: 100)),
                  );
                },
              )
            : Container(
                color: Colors.grey[800],
                child: const Center(child: Icon(Icons.book, size: 100)),
              ),
      ),
    );
  }

  Widget _buildNovelDetails(NovelInfo novel) {
    final textTheme = Theme.of(context).textTheme;

    // --- AQUI ESTÁ A CORREÇÃO ---
    // 1. Pega os capítulos, usando '?? []' para garantir que nunca seja nulo.
    final List<List<String>> chapters = novel.chapters ?? [];

    // 2. Aplica a reversão na lista segura (não-nula).
    final Iterable<List<String>> chapterList = _chaptersReversed
        ? chapters.reversed
        : chapters;
    // --- FIM DA CORREÇÃO ---

    // Também tornamos a lista de gêneros segura, como instruído.
    final List<List<String>> genres = novel.genres ?? [];

    return SliverList(
      delegate: SliverChildListDelegate([
        // --- Gêneros (Agora seguro) ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: genres.map((genre) {
              // Usa a lista 'genres' segura
              return Chip(label: Text(genre[1]));
            }).toList(),
          ),
        ),

        // --- Descrição (Já era seguro) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(novel.desc, style: textTheme.bodyMedium),
        ),

        // --- Cabeçalho dos Capítulos (Já era seguro) ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Chapters', style: textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Invert chapter order',
                onPressed: () {
                  setState(() {
                    _chaptersReversed = !_chaptersReversed;
                  });
                },
              ),
            ],
          ),
        ),

        // --- Lista de Capítulos (Agora segura) ---
        ...chapterList.map((chapter) {
          // Usa a 'chapterList' segura
          final chapterTitle = chapter[0];
          final chapterId = chapter[1];

          return ListTile(
            title: Text(chapterTitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapterDetailPage(
                    novelId: widget.novelId,
                    chapterId: chapterId,
                  ),
                ),
              );
            },
          );
        }).toList(),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ]),
    );
  }
}
