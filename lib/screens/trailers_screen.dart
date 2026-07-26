import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/drama.dart';
import '../services/tmdb_service.dart';

class TrailerEntry {
  final Drama drama;
  final String youtubeKey;
  TrailerEntry(this.drama, this.youtubeKey);
}

class TrailersScreen extends StatefulWidget {
  const TrailersScreen({super.key});

  @override
  State<TrailersScreen> createState() => _TrailersScreenState();
}

class _TrailersScreenState extends State<TrailersScreen> {
  final TmdbService _tmdb = TmdbService();
  List<TrailerEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final trending = await _tmdb.getTrending();
    final entries = <TrailerEntry>[];
    // Limit lookups to keep this quick — trending list is already ranked.
    for (final drama in trending.take(15)) {
      final key = await _tmdb.getTrailerKey(drama.tmdbId);
      if (key != null) {
        entries.add(TrailerEntry(drama, key));
      }
    }
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _play(String youtubeKey) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$youtubeKey');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Trailers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? const Center(
                    child: Text('No trailers found', style: TextStyle(color: Color(0xFF9CA3AF))),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return _buildRow(entry);
                    },
                  ),
      ),
    );
  }

  Widget _buildRow(TrailerEntry entry) {
    final thumb =
        'https://img.youtube.com/vi/${entry.youtubeKey}/hqdefault.jpg';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _play(entry.youtubeKey),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                entry.drama.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
