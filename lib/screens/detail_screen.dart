import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/drama.dart';
import '../services/tmdb_service.dart';
import '../services/db_service.dart';

class DetailScreen extends StatefulWidget {
  final int tmdbId;
  const DetailScreen({super.key, required this.tmdbId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TmdbService _tmdb = TmdbService();
  final DbService _db = DbService();

  Drama? _drama;
  List<Map<String, dynamic>> _cast = [];
  TrackedDrama? _tracked;
  String? _trailerKey;
  bool _loading = true;

  static const statuses = ['plan', 'watching', 'completed', 'dropped'];
  static const statusLabels = {
    'plan': 'Plan to Watch',
    'watching': 'Watching',
    'completed': 'Completed',
    'dropped': 'Dropped',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final drama = await _tmdb.getDetails(widget.tmdbId);
    final cast = await _tmdb.getCast(widget.tmdbId);
    final tracked = await _db.getByTmdbId(widget.tmdbId);
    final trailerKey = await _tmdb.getTrailerKey(widget.tmdbId);
    setState(() {
      _drama = drama;
      _cast = cast;
      _tracked = tracked;
      _trailerKey = trailerKey;
      _loading = false;
    });
  }

  Future<void> _playTrailer() async {
    if (_trailerKey == null) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$_trailerKey');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _setStatus(String status) async {
    final drama = _drama!;
    final existing = _tracked;
    final updated = TrackedDrama(
      id: existing?.id,
      tmdbId: drama.tmdbId,
      title: drama.title,
      posterPath: drama.posterPath,
      status: status,
      totalEpisodes: drama.totalEpisodes,
      watchedEpisodes: existing?.watchedEpisodes ?? 0,
      addedDate: existing?.addedDate ?? DateTime.now().toIso8601String(),
    );
    await _db.addOrUpdate(updated);
    setState(() => _tracked = updated);
  }

  Future<void> _removeTracking() async {
    await _db.remove(widget.tmdbId);
    setState(() => _tracked = null);
  }

  Future<void> _updateProgress(int watched) async {
    await _db.updateProgress(widget.tmdbId, watched);
    setState(() {
      _tracked = _tracked?.copyWith(watchedEpisodes: watched);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final drama = _drama!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFFF9FAFB),
            foregroundColor: const Color(0xFF1F2937),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  drama.backdropPath != null
                      ? CachedNetworkImage(
                          imageUrl: drama.backdropUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[300]),
                  if (_trailerKey != null)
                    Center(
                      child: GestureDetector(
                        onTap: _playTrailer,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drama.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text('${drama.rating.toStringAsFixed(1)} / 10'),
                      if (drama.firstAirDate != null &&
                          drama.firstAirDate!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(_formatDate(drama.firstAirDate!)),
                      ],
                      if (drama.totalEpisodes > 0) ...[
                        const SizedBox(width: 12),
                        Text('${drama.totalEpisodes} episodes'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTrackingCard(drama),
                  const SizedBox(height: 12),
                  _buildScheduleCard(drama),
                  const SizedBox(height: 20),
                  const Text(
                    'Synopsis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    drama.overview.isEmpty ? 'No synopsis available.' : drama.overview,
                    style: const TextStyle(color: Color(0xFF4B5563), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (_cast.isNotEmpty) ...[
                    const Text(
                      'Cast',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final c = _cast[index];
                          return SizedBox(
                            width: 70,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: c['profilePath'] != null
                                      ? CachedNetworkImageProvider(
                                          'https://image.tmdb.org/t/p/w200${c['profilePath']}',
                                        )
                                      : null,
                                  child: c['profilePath'] == null
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c['name'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Drama drama) {
    final started = _formatFullDate(drama.firstAirDate);
    final nextEp = _formatFullDate(drama.nextEpisodeDate);
    final estimatedEnd = drama.estimatedEndDate;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _scheduleRow(Icons.play_circle_outline, 'Started', started ?? 'Unknown'),
          if (nextEp != null) ...[
            const SizedBox(height: 8),
            _scheduleRow(Icons.event_available, 'Next episode', nextEp),
          ],
          if (estimatedEnd != null) ...[
            const SizedBox(height: 8),
            _scheduleRow(
              Icons.flag_outlined,
              'Estimated finish',
              '${DateFormat('MMM d, yyyy').format(estimatedEnd)} (est.)',
            ),
          ] else if (drama.status == 'Ended' && drama.lastEpisodeDate != null) ...[
            const SizedBox(height: 8),
            _scheduleRow(
              Icons.flag_outlined,
              'Ended',
              _formatFullDate(drama.lastEpisodeDate) ?? 'Unknown',
            ),
          ],
        ],
      ),
    );
  }

  Widget _scheduleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String? _formatFullDate(String? date) {
    if (date == null) return null;
    try {
      final d = DateTime.parse(date);
      return DateFormat('MMM d, yyyy').format(d);
    } catch (_) {
      return date;
    }
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('yyyy').format(d);
    } catch (_) {
      return date;
    }
  }

  Widget _buildTrackingCard(Drama drama) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((s) {
              final selected = _tracked?.status == s;
              return ChoiceChip(
                label: Text(statusLabels[s]!),
                selected: selected,
                selectedColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF4B5563),
                  fontSize: 12,
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                onSelected: (_) => _setStatus(s),
              );
            }).toList(),
          ),
          if (_tracked != null) ...[
            const SizedBox(height: 12),
            if (drama.totalEpisodes > 0)
              Row(
                children: [
                  Text(
                    'Episode ${_tracked!.watchedEpisodes} / ${drama.totalEpisodes}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Expanded(
                    child: Slider(
                      value: _tracked!.watchedEpisodes
                          .clamp(0, drama.totalEpisodes)
                          .toDouble(),
                      min: 0,
                      max: drama.totalEpisodes.toDouble(),
                      divisions: drama.totalEpisodes > 0 ? drama.totalEpisodes : 1,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (v) => _updateProgress(v.round()),
                    ),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _removeTracking,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
