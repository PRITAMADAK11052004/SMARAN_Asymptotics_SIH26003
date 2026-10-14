import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// RadioStation
// =============================================================================

/// A radio station in Smaran.
///
/// Stations are fetched from the public Radio Browser API when online, and
/// cached locally for offline use. If the API is unreachable on first launch,
/// a small fallback list is shown.
class RadioStation {
  final String id;
  final String name;
  final String frequency;
  final String location;
  final String language;
  final String category;
  final List<String> urls;
  final String initials;
  final int logoColorValue;

  const RadioStation({
    required this.id,
    required this.name,
    required this.frequency,
    required this.location,
    required this.language,
    required this.category,
    required this.urls,
    required this.initials,
    required this.logoColorValue,
  });

  bool get canStream => urls.isNotEmpty;
}

// =============================================================================
// Fallback list — shown only if API + cache both fail on first launch.
// =============================================================================

const nerRadioStationsFallback = <RadioStation>[
  RadioStation(
    id: 'fallback_vividh_bharati',
    name: 'Vividh Bharati',
    frequency: '100.8 MHz',
    location: 'Guwahati',
    language: 'Hindi / Assamese',
    category: 'music',
    initials: 'VB',
    logoColorValue: 0xFFE49A1E,
    urls: [
      'https://air.pc.cdn.bitgravity.com/air/live/pbaudio001/playlist.m3u8',
    ],
  ),
  RadioStation(
    id: 'fallback_akashvani_guwahati',
    name: 'Akashvani Guwahati',
    frequency: '101.6 MHz',
    location: 'Guwahati',
    language: 'Assamese',
    category: 'talk',
    initials: 'AG',
    logoColorValue: 0xFF4F743D,
    urls: [
      'https://air.pc.cdn.bitgravity.com/air/live/pbaudio133/playlist.m3u8',
    ],
  ),
  RadioStation(
    id: 'fallback_fm_gold',
    name: 'AIR FM Gold',
    frequency: '101.5 MHz',
    location: 'Guwahati',
    language: 'Hindi',
    category: 'retro',
    initials: 'FG',
    logoColorValue: 0xFFB8873A,
    urls: [
      'https://air.pc.cdn.bitgravity.com/air/live/pbaudio005/playlist.m3u8',
    ],
  ),
];

// =============================================================================
// RadioBrowserService — fetches live Indian stations, caches for 7 days.
// =============================================================================

/// Singleton service that provides the list of available radio stations.
///
/// Flow:
///   1. On init, tries to load cached stations from SharedPreferences.
///   2. If cache is empty or older than 7 days, fetches fresh data from
///      the Radio Browser API (radio-browser.info).
///   3. Filters to relevant Indian / Akashvani / AIR stations.
///   4. Falls back to [nerRadioStationsFallback] if everything fails.
class RadioBrowserService extends ChangeNotifier {
  RadioBrowserService._();
  static final RadioBrowserService instance = RadioBrowserService._();

  static const _cacheKey = 'radio_browser_cache_v1';
  static const _cacheTtl = Duration(days: 7);
  static const _apiBase = 'https://de1.api.radio-browser.info/json';
  static const _userAgent = 'SmaranRadio/1.0';

  List<RadioStation> _stations = [];
  bool _loading = false;

  /// The current station list.
  ///
  /// Always returns a non-empty list. If the API has not loaded yet or
  /// failed, returns the fallback list.
  List<RadioStation> get stations {
    if (_stations.isNotEmpty) return _stations;
    return nerRadioStationsFallback;
  }

  bool get isLoading => _loading;

  /// Load cached stations or fetch fresh ones.
  /// Call once at app start (in main.dart).
  Future<void> init() async {
    await _loadFromCache();
    if (_stations.isEmpty) {
      await refresh();
    }
  }

  /// Force a fresh fetch from the API.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '$_apiBase/stations/search'
        '?countrycode=IN'
        '&limit=300'
        '&hidebroken=true'
        '&order=clickcount'
        '&reverse=true',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        _loading = false;
        notifyListeners();
        return;
      }

      final raw = jsonDecode(res.body) as List;
      final parsed = <RadioStation>[];
      final seenNames = <String>{};

      for (final item in raw) {
        final station = _parseApiStation(item);
        if (station == null) continue;
        final key = station.name.toLowerCase().trim();
        if (seenNames.contains(key)) continue;
        seenNames.add(key);
        parsed.add(station);
      }

      if (parsed.isNotEmpty) {
        _stations = parsed;
        await _saveToCache();
      }
    } catch (_) {
      // Keep cached data on error.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── API parsing ─────────────────────────────────────────────

  RadioStation? _parseApiStation(dynamic item) {
    try {
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) return null;

      // Prefer url_resolved (already resolved by the API), fall back to url.
      final resolvedUrl = item['url_resolved']?.toString().trim() ?? '';
      final rawUrl = item['url']?.toString().trim() ?? '';
      final url = resolvedUrl.isNotEmpty ? resolvedUrl : rawUrl;
      if (url.isEmpty) return null;

      // Only keep stations that look Indian/AIR-related.
      final lower = name.toLowerCase();
      final relevant = lower.contains('akashvani') ||
          lower.contains('vividh') ||
          lower.contains('fm gold') ||
          lower.contains('fm rainbow') ||
          lower.contains('all india radio') ||
          lower.contains('air fm') ||
          lower.contains('air ');

      if (!relevant) return null;

      final state = item['state']?.toString().trim() ?? '';
      final language = item['language']?.toString().trim() ?? '';
      final codec = item['codec']?.toString().toLowerCase() ?? '';

      // Skip any video codecs — they won't stream audio-only.
      if (codec.contains('video') || codec.contains('webm')) return null;

      // Detect category from the name.
      String category;
      if (lower.contains('vividh') ||
          lower.contains('rainbow') ||
          lower.contains('fm gold')) {
        category = 'music';
      } else if (lower.contains('news')) {
        category = 'news';
      } else {
        category = 'talk';
      }

      return RadioStation(
        id: item['stationuuid']?.toString() ?? url.hashCode.toString(),
        name: name,
        frequency: 'Live',
        location: state.isEmpty ? 'India' : state,
        language: language.isEmpty ? 'Hindi' : language,
        category: category,
        urls: [url],
        initials: name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'R',
        logoColorValue: _colorFor(name),
      );
    } catch (_) {
      return null;
    }
  }

  /// Deterministic color from station name — so the same station always
  /// gets the same background color.
  int _colorFor(String name) {
    const palette = [
      0xFF4F743D,
      0xFFE49A1E,
      0xFF2E7D68,
      0xFFC97A8B,
      0xFFB8873A,
      0xFF4A7FA0,
      0xFF6B5B95,
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  // ── Cache ───────────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        (map['savedAt'] as num?)?.toInt() ?? 0,
      );

      if (DateTime.now().difference(savedAt) > _cacheTtl) return;

      final list = (map['stations'] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return RadioStation(
          id: m['id'] as String,
          name: m['name'] as String,
          frequency: m['frequency'] as String,
          location: m['location'] as String,
          language: m['language'] as String,
          category: m['category'] as String,
          urls: List<String>.from(m['urls'] as List),
          initials: m['initials'] as String,
          logoColorValue: m['logoColorValue'] as int,
        );
      }).toList();

      if (list.isNotEmpty) _stations = list;
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'stations': _stations
            .map((s) => {
                  'id': s.id,
                  'name': s.name,
                  'frequency': s.frequency,
                  'location': s.location,
                  'language': s.language,
                  'category': s.category,
                  'urls': s.urls,
                  'initials': s.initials,
                  'logoColorValue': s.logoColorValue,
                })
            .toList(),
      };
      await prefs.setString(_cacheKey, jsonEncode(payload));
    } catch (_) {}
  }
}