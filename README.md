# NovelHub

A feature-rich Flutter application for reading and managing novels from multiple online sources. NovelHub aggregates content from various novel platforms and provides an enhanced reading experience with EPUB export functionality.

## 🚀 Features

- **Multi-source Novel Aggregation**: Search and read novels from multiple platforms including CentralNovel, Illusia, and NovelMania
- **Comprehensive Search**: Find novels by title across all integrated sources
- **Detailed Novel Information**: View novel descriptions, covers, genres, and chapter lists
- **Enhanced Reading Experience**: Read chapters in a clean, distraction-free interface with previous/next navigation
- **Chapter Management**: Browse chapters with sorting options and easy navigation
- **EPUB Export**: Download entire novels or selected chapters as EPUB files for offline reading
- **Customizable Downloads**: Select specific chapter ranges for EPUB creation
- **Dark Theme**: Reading-friendly dark mode interface

## 🛠️ Technologies Used

- **Flutter**: Cross-platform mobile application framework
- **Dart**: Programming language for Flutter applications
- **HTML Parsing**: Parse content from various novel websites
- **HTTP Client (Dio)**: Handle API requests and web scraping
- **Archives (Zip)**: Create EPUB files (which are essentially ZIP archives)
- **Path Provider**: Manage file system paths for downloads

## 📱 Screenshots

*Note: Actual screenshots would be added here in a real implementation*

## 📋 Requirements

- Flutter SDK (version 3.9.0 or higher)
- Dart SDK (version 3.9.0 or higher)
- Internet connection for fetching novel content

## 🚀 Getting Started

### Prerequisites

Make sure you have Flutter installed. If not, follow the [official installation guide](https://flutter.dev/docs/get-started/install).

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/NovelHub.git
cd NovelHub
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Building for Production

To build a release version of the app:
```bash
flutter build apk --release
```
or for iOS:
```bash
flutter build ios --release
```

## 🎯 Usage

1. **Search for Novels**: Use the search bar on the home screen to search for novels across all integrated sources
2. **Browse Latest Releases**: View the latest releases from all platforms when not searching
3. **Read Novels**: Tap on any novel to view its details and chapters
4. **Navigate Chapters**: Use the previous/next buttons at the bottom of each chapter
5. **Export as EPUB**: Tap the download icon on the novel details screen to create an EPUB file
6. **Customize Downloads**: Select specific chapters to include in your EPUB export

## 🏗️ Architecture

The application follows a modular architecture with the following key components:

### Models
- `NovelSearchResult`: Represents a novel in search results
- `NovelInfo`: Contains detailed information about a novel
- `ChapterContent`: Holds chapter content with navigation data

### Services
- `NovelApiService`: Handles all data fetching from web sources through scraping
- Supports multiple platforms (CentralNovel, Illusia, NovelMania)

### Screens
- `HomeScreen`: Main search and browsing interface
- `NovelDetailPage`: Shows novel details, description, genres, and chapters
- `ChapterDetailPage`: Displays chapter content with navigation
- `EpubDownloaderPage`: Manages EPUB file creation and download options

## 🌐 Supported Sources

- **CentralNovel**: Brazilian Portuguese novel platform
- **Illusia**: Portuguese novel reading platform  
- **NovelMania**: Portuguese novel aggregation platform

## ⚙️ Configuration

The application can be configured through the `pubspec.yaml` file. Key dependencies include:

- `dio`: HTTP client for web requests
- `html`: HTML parsing for extracting content
- `archive`: Create ZIP/EPUB archives
- `path_provider`: File system path management
- `file_picker`: File selection interface

## 🔧 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues and Bugs

If you encounter any issues or bugs, please open an issue in the repository with detailed information about the problem and steps to reproduce it.

## 🤝 Support

For support, please open an issue in the repository or contact the project maintainers.

---

**Note**: This application performs web scraping to aggregate content from various novel platforms. Please respect the terms of service of these platforms and use the application responsibly.