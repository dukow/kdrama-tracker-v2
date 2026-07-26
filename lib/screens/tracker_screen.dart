import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/drama.dart';
import '../services/db_service.dart';
import 'detail_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  final DbService _db = DbService();
  late TabController _tabController;
  static const tabs = ['watching', 'plan', 'completed', 'dropped'];
  static const labels = ['Watching', 'Plan to Watch', 'Completed', 'Dropped'];

  List<TrackedDrama> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _db.getAll();
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF6366F1),
          tabs: labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: tabs.map((status) {
                  final items = _all.where((d) => d.status == status).toList();
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Nothing here yet', style: TextStyle(color: Color(0xFF9CA3AF))),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final d = items[index];
                      return _buildRow(d);
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildRow(TrackedDrama d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(tmdbId: d.tmdbId)),
          );
          _load();
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: d.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: d.posterUrl,
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(width: 56, height: 80, color: Colors.grey[200]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  if (d.totalEpisodes > 0)
                    Text(
                      'Ep ${d.watchedEpisodes} / ${d.totalEpisodes}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
