import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import '../models/novel_models.dart';
import '../services/novel_api_service.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:markdown/markdown.dart' as md;
import 'package:html_unescape/html_unescape.dart';

class EpubDownloadPage extends StatefulWidget {
  final NovelInfo novelInfo;
  final String novelId;

  const EpubDownloadPage({
    Key? key,
    required this.novelInfo,
    required this.novelId,
  }) : super(key: key);

  @override
  _EpubDownloadPageState createState() => _EpubDownloadPageState();
}

class _EpubDownloadPageState extends State<EpubDownloadPage> {
  final NovelApiService _apiService = NovelApiService();
  final HtmlUnescape unescape = HtmlUnescape();
  bool _isDownloading = false;
  int _downloadedChapters = 0;
  int _totalChapters = 0;
  String _statusMessage = '';
  double _progress = 0.0;

  // User options for download
  bool _includeAllChapters = true;
  int _startChapter = 1;
  int _endChapter = 0;

  @override
  void initState() {
    super.initState();
    _endChapter = widget.novelInfo.chapters.length;
  }

  Future<void> _downloadNovelAsEpub() async {
    setState(() {
      _isDownloading = true;
      _totalChapters = _includeAllChapters
          ? widget.novelInfo.chapters.length
          : (_endChapter - _startChapter + 1);
      _downloadedChapters = 0;
      _progress = 0.0;
      _statusMessage = 'Iniciando download...';
    });

    try {
      // Create a temporary directory for the epub files
      final tempDir = await getTemporaryDirectory();
      final epubDir = Directory(
        '${tempDir.path}/epub_${DateTime.now().millisecondsSinceEpoch}',
      );
      await epubDir.create();

      // Create EPUB structure
      final archive = Archive();

      // Add mimetype file (must be the first file, uncompressed)
      archive.addFile(
        ArchiveFile('mimetype', 0, utf8.encode('application/epub+zip')),
      );

      // Add META-INF/container.xml
      final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(
        ArchiveFile(
          'META-INF/container.xml',
          containerXml.length,
          utf8.encode(containerXml),
        ),
      );

      // Prepare content for OPF file
      final contentOpf = StringBuffer();
      contentOpf.write('<?xml version="1.0" encoding="UTF-8"?>\n');
      contentOpf.write(
        '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="bookid">\n',
      );
      contentOpf.write(
        '  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">\n',
      );
      contentOpf.write(
        '    <dc:title>${_escapeXml(widget.novelInfo.nome)}</dc:title>\n',
      );
      contentOpf.write(
        '    <dc:creator opf:role="aut">NovelHub App</dc:creator>\n',
      );
      contentOpf.write('    <dc:language>pt-BR</dc:language>\n');
      contentOpf.write(
        '    <dc:description>${_escapeXml(widget.novelInfo.desc)}</dc:description>\n',
      );
      contentOpf.write(
        '    <dc:identifier id="bookid">urn:uuid:${_generateUuid()}</dc:identifier>\n',
      );
      contentOpf.write('  </metadata>\n');
      contentOpf.write('  <manifest>\n');
      contentOpf.write(
        '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>\n',
      );

      // Add cover if available
      String coverId = '';
      if (widget.novelInfo.cover.isNotEmpty) {
        try {
          final coverFile = await _downloadImage(
            widget.novelInfo.cover,
            'cover',
          );
          if (coverFile != null) {
            coverId = 'cover-image';
            archive.addFile(
              ArchiveFile(
                'OEBPS/cover.jpg',
                coverFile.lengthSync(),
                await coverFile.readAsBytes(),
              ),
            );
            contentOpf.write(
              '    <item id="$coverId" href="cover.jpg" media-type="image/jpeg"/>\n',
            );
          }
        } catch (e) {
          print('Erro ao baixar a capa: $e');
        }
      }

      // Add chapters
      final chaptersToDownload = _includeAllChapters
          ? widget.novelInfo.chapters
          : widget.novelInfo.chapters
                .skip(_startChapter - 1)
                .take(_endChapter - _startChapter + 1)
                .toList();

      for (int i = 0; i < chaptersToDownload.length; i++) {
        final chapterId = 'chapter-${i + 1}';
        contentOpf.write(
          '    <item id="$chapterId" href="chapter-${i + 1}.html" media-type="application/xhtml+xml"/>\n',
        );
      }

      contentOpf.write('  </manifest>\n');
      contentOpf.write('  <spine toc="ncx">\n');
      if (coverId.isNotEmpty) {
        contentOpf.write('    <itemref idref="$coverId"/>\n');
      }

      for (int i = 0; i < chaptersToDownload.length; i++) {
        final chapterId = 'chapter-${i + 1}';
        contentOpf.write('    <itemref idref="$chapterId"/>\n');
      }

      contentOpf.write('  </spine>\n');
      contentOpf.write('</package>');

      archive.addFile(
        ArchiveFile(
          'OEBPS/content.opf',
          contentOpf.length,
          utf8.encode(contentOpf.toString()),
        ),
      );

      // Create TOC file (toc.ncx)
      final tocNcx =
          '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${_generateUuid()}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${_escapeXml(widget.novelInfo.nome)}</text>
  </docTitle>
  <navMap>
    ${chaptersToDownload.asMap().entries.map((entry) {
            final index = entry.key;
            final chapter = entry.value;
            final chapterName = chapter[0];
            return '<navPoint id="navpoint-${index + 1}" playOrder="${index + 1}"><navLabel><text>${_escapeXml(chapterName)}</text></navLabel><content src="chapter-${index + 1}.html"/></navPoint>';
          }).join('\n    ')}
  </navMap>
</ncx>''';
      archive.addFile(
        ArchiveFile('OEBPS/toc.ncx', tocNcx.length, utf8.encode(tocNcx)),
      );

      // Download chapters using the already defined chaptersToDownload variable from earlier in the function
      for (int i = 0; i < chaptersToDownload.length; i++) {
        if (!_isDownloading) break; // Cancel if user stopped

        final chapter = chaptersToDownload[i];
        final chapterName = chapter[0];
        final chapterId = chapter[1];

        setState(() {
          _downloadedChapters = i + 1;
          _progress = _downloadedChapters / _totalChapters;
          _statusMessage =
              'Baixando capítulo $_downloadedChapters de $_totalChapters: $chapterName';
        });

        try {
          final chapterContent = await _apiService.getChapterContentOnly(
            widget.novelId,
            chapterId,
          );

          String cleanHtml = unescape.convert(chapterContent.content);
          String markdown = html2md.convert(cleanHtml);
          String cleanedHtml = md.markdownToHtml(markdown);

          // Create chapter XHTML content - use both title and subtitle if available
          final chapterTitle = chapterContent.title.isNotEmpty ? chapterContent.title : chapterName;
          final chapterSubtitle = chapterContent.subtitle.isNotEmpty ? chapterContent.subtitle : '';
          final chapterXhtml = chapterSubtitle.isNotEmpty
              ? '''
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>$chapterTitle</title>
  <link rel="stylesheet" type="text/css" href="style.css"/>
</head>
<body>
  <h1>$chapterTitle</h1>
  <h2>$chapterSubtitle</h2>
  <div class="chapter-content">$cleanedHtml</div>
</body>
</html>'''
              : '''
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>$chapterTitle</title>
  <link rel="stylesheet" type="text/css" href="style.css"/>
</head>
<body>
  <h1>$chapterTitle</h1>
  <div class="chapter-content">$cleanedHtml</div>
</body>
</html>''';

          // Add chapter to archive
          archive.addFile(
            ArchiveFile(
              'OEBPS/chapter-${i + 1}.html',
              chapterXhtml.length,
              utf8.encode(chapterXhtml),
            ),
          );
        } catch (e) {
          print('Erro ao baixar capítulo $chapterName: $e');
          // Continue with next chapter
        }
      }

      // Add basic CSS
      final cssContent = '''body {
  font-family: Arial, sans-serif;
  line-height: 1.6;
  margin: 20px;
  font-size: 16px;
}
h1, h2, h3 {
  color: #333;
  border-bottom: 1px solid #ddd;
  padding-bottom: 10px;
}
.chapter-content {
  margin-top: 20px;
}
img {
  max-width: 100%;
  height: auto;
}''';
      archive.addFile(
        ArchiveFile(
          'OEBPS/style.css',
          cssContent.length,
          utf8.encode(cssContent),
        ),
      );

      if (_isDownloading) {
        // Encode the archive as a ZIP file (EPUB is a ZIP archive)
        final zipBytes = ZipEncoder().encode(archive);

        // On Android, save to the Downloads directory for maximum accessibility
        String downloadPath;

        if (Platform.isAndroid) {
          try {
            // Use external_path to get the Downloads directory
            final downloadsDir =
                await ExternalPath.getExternalStoragePublicDirectory(
                  ExternalPath.DIRECTORY_DOWNLOAD,
                );
            downloadPath = downloadsDir;
          } catch (e) {
            // Fallback to external storage directory if Downloads fails
            final externalDir = await getExternalStorageDirectory();
            downloadPath =
                externalDir?.path ??
                (await getApplicationDocumentsDirectory()).path;
          }
        } else {
          // For other platforms, use application documents directory
          downloadPath = (await getApplicationDocumentsDirectory()).path;
        }

        final epubFileName = _sanitizeFileName('${widget.novelInfo.nome}.epub');
        final epubFilePath = '$downloadPath/$epubFileName';

        final epubFile = File(epubFilePath);
        await epubFile.writeAsBytes(
          zipBytes!,
        ); // The ! is safe here as zipBytes won't be null

        setState(() {
          _statusMessage =
              'Download concluído! ${_downloadedChapters} capítulos salvos.';
          _progress = 1.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('EPUB salvo em: $epubFilePath'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'Download cancelado pelo usuário';
        });
      }

      // Clean up temporary directory
      await epubDir.delete(recursive: true);
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar EPUB: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  String _padNumber(int number) {
    return number.toString().padLeft(3, '0');
  }

  String _sanitizeFileName(String fileName) {
    // Remove characters that are invalid in file names
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll('\'', '&apos;');
  }

  String _generateUuid() {
    // Generate a simple UUID (for EPUB compatibility)
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<int?> _showChapterSelectionDialog(String title, int currentValue) async {
    return await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.novelInfo.chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = widget.novelInfo.chapters[index];
                    final chapterId = chapter[1];
                    final chapterTitle = chapter[0];
                    final isSelected = (index + 1) == currentValue;

                    return ListTile(
                      title: Text(
                        'Capítulo ${index + 1}: $chapterTitle',
                        style: isSelected
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                      subtitle: Text('ID: $chapterId'),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () {
                        Navigator.of(context).pop(index + 1); // Return 1-based index
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cancel
                },
                child: const Text('Cancelar'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _downloadImage(String imageUrl, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final imageFile = File('${tempDir.path}/$fileName.jpg');

      final response = await Dio().get<ResponseBody>(
        imageUrl,
        options: Options(responseType: ResponseType.stream),
      );

      // --- Início da Correção ---

      // 1. Abra o sink para escrever no arquivo
      final fileStream = imageFile.openWrite();

      // 2. Escute o stream de dados e adicione cada pedaço ao sink
      await response.data!.stream.forEach((chunk) {
        fileStream.add(chunk);
      });

      // 3. Feche o sink (isso também chama flush automaticamente)
      await fileStream.close();

      // --- Fim da Correção ---

      return imageFile;
    } catch (e) {
      print('Erro ao baixar imagem: $e');
      return null;
    }
  }

  void _startDownload() {
    _downloadNovelAsEpub();
  }

  void _stopDownload() {
    setState(() {
      _isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download EPUB: ${widget.novelInfo.nome}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isDownloading)
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: _stopDownload,
              tooltip: 'Cancelar download',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opções de Download',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _includeAllChapters,
                          onChanged: _isDownloading
                              ? null
                              : (value) {
                                  setState(() {
                                    _includeAllChapters = value!;
                                    if (_includeAllChapters) {
                                      _startChapter = 1;
                                      _endChapter = widget.novelInfo.chapters.length;
                                    }
                                  });
                                },
                        ),
                        const Text('Incluir todos os capítulos'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_includeAllChapters) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isDownloading ? null : () async {
                                final selectedChapter = await _showChapterSelectionDialog(
                                  'Selecione o capítulo inicial',
                                  _startChapter,
                                );
                                if (selectedChapter != null) {
                                  setState(() {
                                    _startChapter = selectedChapter;
                                    // Make sure end chapter is not before start
                                    if (_endChapter < _startChapter) {
                                      _endChapter = _startChapter;
                                    }
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Capítulo inicial',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Capítulo ${_startChapter}: ${widget.novelInfo.chapters[_startChapter - 1][0]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isDownloading ? null : () async {
                                final selectedChapter = await _showChapterSelectionDialog(
                                  'Selecione o capítulo final',
                                  _endChapter,
                                );
                                if (selectedChapter != null) {
                                  setState(() {
                                    _endChapter = selectedChapter;
                                    // Make sure end chapter is not before start
                                    if (_endChapter < _startChapter) {
                                      _startChapter = _endChapter;
                                    }
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Capítulo final',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Capítulo ${_endChapter}: ${widget.novelInfo.chapters[_endChapter - 1][0]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Display information about the selected range with chapter titles
                      if (widget.novelInfo.chapters.isNotEmpty &&
                          _startChapter >= 1 &&
                          _startChapter <= widget.novelInfo.chapters.length &&
                          _endChapter >= _startChapter &&
                          _endChapter <= widget.novelInfo.chapters.length) ...[
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_endChapter - _startChapter + 1} capítulo(s) serão incluídos',
                                style: const TextStyle(fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Total de capítulos: ${widget.novelInfo.chapters.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isDownloading) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progresso do Download',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).round()}% - $_statusMessage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_downloadedChapters de $_totalChapters capítulos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isDownloading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Baixando...'),
                            ],
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download),
                              SizedBox(width: 8),
                              Text('Baixar EPUB'),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O download pode levar vários minutos dependendo do número de capítulos',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
