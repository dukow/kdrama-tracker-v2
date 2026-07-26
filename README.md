# KDrama Tracker (Standalone Mobile App)

Fully standalone Android app — no VPS, no backend. Talks directly to TMDb's
API for search/trending/details, and stores your personal tracking list
locally on-device with SQLite.

## Features
- **Discover** tab: Trending / Today (airing today) / Upcoming — three sub-tabs
- **News**: K-drama entertainment news pulled live from Soompi's RSS feed
- **Trailers**: trending dramas with YouTube trailers, tap to play
- **Search**
- **Drama detail page**: rating, synopsis, cast, and a Schedule card showing
  started date, next episode date, and an *estimated* finish date (see note
  below), plus a trailer play button over the backdrop
- **Personal tracker**: Watching / Plan to Watch / Completed / Dropped, with
  an episode progress slider (e.g. 5/16 watched)

## How to build

1. Push this whole folder to a new GitHub repo (or add to an existing one).
   Make sure `.github/workflows/build-apk.yml` lands with the dot-prefix
   intact — check this after upload, it's a recurring gotcha.
2. Go to the repo's **Actions** tab → "Build KDrama Tracker APK" → **Run workflow**.
3. When it finishes, download the `kdrama-tracker-apk` artifact — it contains
   split APKs per architecture (arm64-v8a is the one for almost all modern
   phones).
4. Transfer the APK to your phone and install (enable "install from unknown
   sources" if prompted).

## Structure
```
lib/
  main.dart              - app entry, bottom nav, theme
  models/drama.dart      - Drama + TrackedDrama models
  services/
    tmdb_service.dart    - TMDb API calls
    db_service.dart      - local SQLite tracking storage
  screens/
    home_screen.dart     - trending feed
    search_screen.dart   - search
    detail_screen.dart   - detail + tracking controls
    tracker_screen.dart  - your tracked list, tabbed by status
  widgets/drama_card.dart
```

## Notes
- TMDb API key is embedded (`4b5648e58a01b6aec87e615f9cdb3922`) — same one
  used in the original web tracker.
- **News** comes from Soompi's public RSS feed (`soompi.com/feed`), since
  TMDb has no news endpoint. If you'd rather pull from a different outlet,
  say the word and I'll swap the feed URL in `news_service.dart`.
- **Estimated finish date** on the detail page is a heuristic, not official
  data — TMDb doesn't publish a real end date for ongoing shows. It's
  calculated from the next episode's air date plus the remaining episode
  count at a ~3.5 day/episode pace (typical twice-weekly K-drama slot), and
  is always labeled "(est.)" in the UI so it reads as an estimate, not a fact.
- This is a release build but unsigned with a debug key by default via
  Flutter's standard build — fine for personal sideloading. Say the word if
  you want a proper signing key set up for Play Store distribution later.
- All tracking data lives only on the device it's installed on (SQLite,
  no sync). If you want cross-device sync later we'd need to bring a backend
  back in — but for now this matches "no VPS."
