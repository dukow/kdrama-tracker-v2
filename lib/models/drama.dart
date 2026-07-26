class Drama {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double rating;
  final String? firstAirDate;
  final int totalEpisodes;
  final String? status;
  final String? nextEpisodeDate;
  final String? lastEpisodeDate;
  final int episodesAiredSoFar;

  Drama({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview = '',
    this.rating = 0.0,
    this.firstAirDate,
    this.totalEpisodes = 0,
    this.status,
    this.nextEpisodeDate,
    this.lastEpisodeDate,
    this.episodesAiredSoFar = 0,
  });

  /// Rough estimate only — TMDb doesn't provide a real "expected end date"
  /// for ongoing shows. Derived from the next episode date plus remaining
  /// episodes at a ~3.5 day/episode pace (typical twice-weekly K-drama slot).
  DateTime? get estimatedEndDate {
    if (status != 'Returning Series' && status != 'In Production') return null;
    if (nextEpisodeDate == null || totalEpisodes == 0) return null;
    try {
      final next = DateTime.parse(nextEpisodeDate!);
      final remaining = totalEpisodes - episodesAiredSoFar;
      if (remaining <= 0) return next;
      return next.add(Duration(days: ((remaining - 1) * 3.5).round()));
    } catch (_) {
      return null;
    }
  }

  String get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';

  factory Drama.fromTmdbJson(Map<String, dynamic> json) {
    return Drama(
      tmdbId: json['id'],
      title: json['name'] ?? json['original_name'] ?? 'Unknown',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'] ?? '',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      firstAirDate: json['first_air_date'],
      totalEpisodes: json['number_of_episodes'] ?? 0,
      status: json['status'],
      nextEpisodeDate: json['next_episode_to_air']?['air_date'],
      lastEpisodeDate: json['last_episode_to_air']?['air_date'],
      episodesAiredSoFar: json['last_episode_to_air']?['episode_number'] ?? 0,
    );
  }
}

class TrackedDrama {
  final int? id;
  final int tmdbId;
  final String title;
  final String? posterPath;
  final String status; // watching, completed, plan, dropped
  final int totalEpisodes;
  final int watchedEpisodes;
  final String addedDate;

  TrackedDrama({
    this.id,
    required this.tmdbId,
    required this.title,
    this.posterPath,
    required this.status,
    this.totalEpisodes = 0,
    this.watchedEpisodes = 0,
    required this.addedDate,
  });

  String get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'title': title,
      'posterPath': posterPath,
      'status': status,
      'totalEpisodes': totalEpisodes,
      'watchedEpisodes': watchedEpisodes,
      'addedDate': addedDate,
    };
  }

  factory TrackedDrama.fromMap(Map<String, dynamic> map) {
    return TrackedDrama(
      id: map['id'],
      tmdbId: map['tmdbId'],
      title: map['title'],
      posterPath: map['posterPath'],
      status: map['status'],
      totalEpisodes: map['totalEpisodes'] ?? 0,
      watchedEpisodes: map['watchedEpisodes'] ?? 0,
      addedDate: map['addedDate'],
    );
  }

  TrackedDrama copyWith({
    String? status,
    int? watchedEpisodes,
    int? totalEpisodes,
  }) {
    return TrackedDrama(
      id: id,
      tmdbId: tmdbId,
      title: title,
      posterPath: posterPath,
      status: status ?? this.status,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      addedDate: addedDate,
    );
  }
}
