import 'package:flutter/material.dart';
import '../models/drama.dart';
import '../services/tmdb_service.dart';
import '../widgets/drama_card.dart';
import 'detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final TmdbService _tmdb = TmdbService();
  late TabController _tabController;

  final Map<String, List<Drama>> _cache = {};
  final Map<String, bool> _loading = {'trending': true, 'today': true, 'upcoming': true};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    _load('trending', () => _tmdb.getTrending());
    _load('today', () => _tmdb.getAiringToday());
    _load('upcoming', () => _tmdb.getUpcoming());
  }

  Future<void> _load(String key, Future<List<Drama>> Function() fetch) async {
    setState(() {
      _loading[key] = true;
      _errors[key] = null;
    });
    try {
      final results = await fetch();
      setState(() {
        _cache[key] = results;
        _loading[key] = false;
      });
    } catch (e) {
      setState(() {
        _errors[key] = 'Could not load';
        _loading[key] = false;
      });
    }
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
        title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid('trending'),
          _buildGrid('today'),
          _buildGrid('upcoming'),
        ],
      ),
    );
  }

  Widget _buildGrid(String key) {
    final loading = _loading[key] ?? true;
    final error = _errors[key];
    final items = _cache[key] ?? [];

    return RefreshIndicator(
      onRefresh: () => _load(
        key,
        key == 'trending'
            ? () => _tmdb.getTrending()
            : key == 'today'
                ? () => _tmdb.getAiringToday()
                : () => _tmdb.getUpcoming(),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error))
              : items.isEmpty
                  ? const Center(
                      child: Text('Nothing here right now', style: TextStyle(color: Color(0xFF9CA3AF))),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final drama = items[index];
                        return DramaCard(
                          drama: drama,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(tmdbId: drama.tmdbId),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
