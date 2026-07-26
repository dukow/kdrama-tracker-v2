class NewsItem {
  final String title;
  final String link;
  final String? imageUrl;
  final DateTime? pubDate;
  final String description;

  NewsItem({
    required this.title,
    required this.link,
    this.imageUrl,
    this.pubDate,
    this.description = '',
  });
}
