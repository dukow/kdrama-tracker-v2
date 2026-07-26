import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drama.dart';

class TmdbService {
  static const String apiKey = '4b5648e58a01b6aec87e615f9cdb3922';
  static const String baseUrl = 'https://api.themoviedb.org/3';

  // Korean (KR) and Chinese (CN, TW, HK) origin TV shows
  static const List<String> dramaRegions = ['KR', 'CN', 'TW', 'HK'];

  Future<List<Drama>> getTrending() async {
    final url = Uri.parse('$baseUrl/trending/tv/week?api_key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load trending dramas');
    }
    final data = jsonDecode(response.body);
    final raw = (data['results'] as List);

    // The trending endpoint has no origin-country filter, so it returns global
    // TV. Filter to Korean/Chinese titles here, and fall back to the unfiltered
    // list if that leaves nothing (rather than showing an empty screen).
    final asian = raw.where((json) {
      final countries = (json['origin_country'] as List?) ?? const [];
      return countries.any((c) => dramaRegions.contains(c));
    }).toList();

    final chosen = asian.isNotEmpty ? asian : raw;
    return chosen.map((json) => Drama.fromTmdbJson(json)).toList();
  }

  /// Dramas with an episode airing today.
  ///
  /// Uses /discover rather than /tv/airing_today because the latter silently
  /// ignores with_origin_country and would return global TV instead of dramas.
  Future<List<Drama>> getAiringToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final url = Uri.parse(
      '$baseUrl/discover/tv?api_key=$apiKey'
      '&with_origin_country=${dramaRegions.join('|')}'
      '&air_date.gte=$today'
      '&air_date.lte=$today'
      '&sort_by=popularity.desc',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load today\'s dramas');
    }
    final data = jsonDecode(response.body);
    return (data['results'] as List)
        .map((json) => Drama.fromTmdbJson(json))
        .toList();
  }

  Future<List<Drama>> getUpcoming() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final url = Uri.parse(
      '$baseUrl/discover/tv?api_key=$apiKey'
      '&with_origin_country=${dramaRegions.join('|')}'
      '&first_air_date.gte=$today'
      '&sort_by=popularity.desc',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load upcoming dramas');
    }
    final data = jsonDecode(response.body);
    return (data['results'] as List)
        .map((json) => Drama.fromTmdbJson(json))
        .toList();
  }

  /// Returns a YouTube trailer key (video id) for the given show, if any.
  Future<String?> getTrailerKey(int tmdbId) async {
    final url = Uri.parse('$baseUrl/tv/$tmdbId/videos?api_key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    final results = (data['results'] as List);
    final trailer = results.firstWhere(
      (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
      orElse: () => results.isNotEmpty ? results.first : null,
    );
    if (trailer == null) return null;
    return trailer['key'];
  }

  Future<List<Drama>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final url = Uri.parse(
      '$baseUrl/search/tv?api_key=$apiKey&query=${Uri.encodeComponent(query)}',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Search failed');
    }
    final data = jsonDecode(response.body);
    final results = (data['results'] as List)
        .map((json) => Drama.fromTmdbJson(json))
        .toList();
    return results;
  }

  Future<Drama> getDetails(int tmdbId) async {
    final url = Uri.parse('$baseUrl/tv/$tmdbId?api_key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load drama details');
    }
    final data = jsonDecode(response.body);
    return Drama.fromTmdbJson(data);
  }

  Future<List<Map<String, dynamic>>> getCast(int tmdbId) async {
    final url = Uri.parse(
      '$baseUrl/tv/$tmdbId/credits?api_key=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    final cast = (data['cast'] as List).take(10).map((c) {
      return {
        'name': c['name'],
        'character': c['character'],
        'profilePath': c['profile_path'],
      };
    }).toList();
    return cast.cast<Map<String, dynamic>>();
  }
}
