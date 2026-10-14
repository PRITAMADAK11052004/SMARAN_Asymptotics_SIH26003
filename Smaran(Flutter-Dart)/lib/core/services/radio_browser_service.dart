import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ner_radio_stations.dart';

class RadioBrowserService {
  RadioBrowserService._();
  static final RadioBrowserService instance = RadioBrowserService._();

  static const _cacheKey = 'radio_browser_cache_v1';
  static const _cacheTtl = Duration(days: 7);
  static const _baseUrl = 'https://de1.api.radio-browser.info/json';
  static const _userAgent = 'SmaranRadio/1.0';

  List<RadioStation> _stations = [];
  List<RadioStation> get stations => _stations;

  bool _loading = false;
  bool get isLoading => _loading;

  Future<void> init() async {
    await _loadFromCache();
    if (_stations.isEmpty) {
      await refresh();
    }
  }

  Future<void> refresh() async {
    _loading = true;
    try {
      final url = Uri.parse(
        '$_baseUrl/stations/search'
        '?countrycode=IN'
        '&limit=200'
        '&hidebroken=true'
        '&order=clickcount'
        '&reverse=true',
      );
      final res = await http.get(url, headers: {'User-Agent': _userAgent});
      if (res.statusCode != 200) return;

      final raw = jsonDecode(res.body) as List;
      final parsed = <RadioStation>[];
      for (final item in raw) {
        final s = _parse(item);
        if (s != null) parsed.add(s);
      }
      _stations = parsed;
      await _saveToCache();
    } catch (_) {
      // Keep cached data on error.
    } finally {
      _loading = false;
    }
  }

  RadioStation? _parse(dynamic item) {
    try {
      final name = item['name']?.toString() ?? '';
      final url = (item['url_resolved'] ?? item['url'])?.toString() ?? '';
      if (name.isEmpty || url.isEmpty) return null;

      final lower = name.toLowerCase();
      // Keep only Indian, Akashvani, or AIR stations.
      final isRelevant = lower.contains('akashvani') ||
          lower.contains('air ') ||
          lower.contains('vividh') ||
          lower.contains('fm gold') ||
          lower.contains('fm rainbow') ||
          lower.contains('all india radio');
      if (!isRelevant) return null;

      return RadioStation(
        id: item['stationuuid']?.toString() ?? url.hashCode.toString(),
        name: name,
        frequency: 'Live',
        location: item['state']?.toString() ?? 'India',
        language: item['language']?.toString() ?? 'Hindi',
        category: 'music',
        urls: [url],
        initials: name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'R',
        logoColorValue: 0xFF4F743D,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        map['savedAt'] as int? ?? 0,
      );
      if (DateTime.now().difference(savedAt) > _cacheTtl) return;

      final list = (map['stations'] as List)
          .map((e) => RadioStation(
                id: e['id'],
                name: e['name'],
                frequency: e['frequency'],
                location: e['location'],
                language: e['language'],
                category: e['category'],
                urls: List<String>.from(e['urls']),
                initials: e['initials'],
                logoColorValue: e['logoColorValue'],
              ))
          .toList();
      _stations = list;
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