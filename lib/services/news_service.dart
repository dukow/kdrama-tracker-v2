import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_item.dart';

class NewsService {
  // Soompi covers K-drama/K-entertainment news broadly.
  static const String feedUrl = 'https://www.soompi.com/feed';

  Future<List<NewsItem>> getNews() async {
    final response = await http.get(Uri.parse(feedUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load news');
    }
    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    return items.map((item) {
      final title = item.getElement('title')?.innerText.trim() ?? '';
      final link = item.getElement('link')?.innerText.trim() ?? '';
      final pubDateStr = item.getElement('pubDate')?.innerText.trim();
      DateTime? pubDate;
      if (pubDateStr != null) {
        try {
          pubDate = HttpDateFormatter.parse(pubDateStr);
        } catch (_) {
          pubDate = null;
        }
      }
      String? imageUrl;
      final enclosure = item.getElement('enclosure');
      if (enclosure != null) {
        imageUrl = enclosure.getAttribute('url');
      }
      imageUrl ??= _extractImageFromContent(item);

      String description = item.getElement('description')?.innerText.trim() ?? '';
      description = _stripHtml(description);

      return NewsItem(
        title: title,
        link: link,
        imageUrl: imageUrl,
        pubDate: pubDate,
        description: description,
      );
    }).toList();
  }

  String? _extractImageFromContent(XmlElement item) {
    final content = item.children
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'encoded')
        .map((e) => e.innerText)
        .join();
    final match = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(content);
    return match?.group(1);
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

/// Minimal RFC 822 date parser for RSS pubDate fields, avoids pulling in
/// an extra dependency just for this.
class HttpDateFormatter {
  static DateTime parse(String input) {
    // Example: "Fri, 25 Jul 2026 10:00:00 +0000"
    final cleaned = input.trim();
    final parts = cleaned.split(' ');
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    // parts: [Fri,, 25, Jul, 2026, 10:00:00, +0000]
    final day = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);
    return DateTime(year, month, day, hour, minute, second);
  }
}
