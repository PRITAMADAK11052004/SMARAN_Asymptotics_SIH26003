import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/ner_radio_stations.dart';

/// Global singleton for the radio player.
///
/// Behavior:
///   - 30-second timeout per URL attempt.
///   - No auto-skip — if all URLs fail, the station stays selected with an
///     error state. The user can tap "Try Again".
///   - No external app launches.
///   - Uses stations from [RadioBrowserService] (API-backed) with a local
///     fallback list.
class RadioPlayerService extends ChangeNotifier {
  RadioPlayerService._();
  static final RadioPlayerService instance = RadioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

  RadioStation? _current;
  RadioStation? get currentStation => _current;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  String _icyTitle = '';
  String get nowPlayingTitle =>
      _icyTitle.isNotEmpty ? _icyTitle : (_current?.name ?? '');

  int _currentIndex = -1;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<IcyMetadata?>? _icySub;
  Timer? _connectTimer;

  /// 30 seconds per URL — enough for slow Indian mobile networks.
  static const Duration _urlTimeout = Duration(seconds: 30);

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;
  bool get hasStation => _current != null;

  /// The current list of stations, from the API service with fallback.
  List<RadioStation> get availableStations =>
      RadioBrowserService.instance.stations;

  Future<void> init() async {
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready ||
          state.processingState == ProcessingState.buffering) {
        if (_loading) {
          _loading = false;
          _connectTimer?.cancel();
        }
      }
      if (state.processingState == ProcessingState.completed) {
        _loading = false;
      }
      notifyListeners();
    });

    try {
      _icySub = _player.icyMetadataStream.listen((meta) {
        if (meta?.info?.title != null) {
          _icyTitle = meta!.info!.title!;
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  Future<void> play(RadioStation station) async {
    if (!station.canStream) {
      _error = 'No stream available.';
      notifyListeners();
      return;
    }

    // Same station → toggle play/pause.
    if (_current?.id == station.id && !hasError) {
      if (_player.playing) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    _error = null;
    _loading = true;
    _current = station;
    _icyTitle = '';
    _currentIndex =
        availableStations.indexWhere((s) => s.id == station.id);
    notifyListeners();

    try {
      await _player.stop();
    } catch (_) {}

    // Try each URL with a 30-second timeout each.
    for (final url in station.urls) {
      try {
        await _player
            .setAudioSource(
              AudioSource.uri(
                Uri.parse(url),
                tag: MediaItem(
                  id: station.id,
                  title: station.name,
                  artist: '${station.location} • ${station.frequency}',
                  album: 'Smaran Radio',
                ),
              ),
            )
            .timeout(_urlTimeout);

        unawaited(_player.play());

        // Wait for actual playback or timeout.
        final ok = await _waitForPlayback(_urlTimeout);
        if (ok) {
          _loading = false;
          notifyListeners();
          return;
        }
      } catch (_) {
        continue;
      }
    }

    // All URLs failed — do NOT auto-skip. Show a calm error state.
    _loading = false;
    _error = 'Could not connect.';
    notifyListeners();
  }

  /// Wait until the player is actually playing or the timeout elapses.
  Future<bool> _waitForPlayback(Duration timeout) {
    final completer = Completer<bool>();
    Timer? timer;
    StreamSubscription<PlayerState>? sub;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    sub = _player.playerStateStream.listen((state) {
      final playing =
          state.playing && state.processingState == ProcessingState.ready;
      if (playing && !completer.isCompleted) {
        completer.complete(true);
      }
    });

    return completer.future.whenComplete(() {
      timer?.cancel();
      sub?.cancel();
    });
  }

  /// Retry the current station.
  Future<void> retry() async {
    final s = _current;
    if (s == null) return;
    final id = s.id;
    _current = null;
    // Small delay so the UI can show the spinner state.
    await Future.delayed(const Duration(milliseconds: 100));
    // Find the station again (in case the list refreshed).
    final match = availableStations.firstWhere(
      (s) => s.id == id,
      orElse: () => s,
    );
    await play(match);
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> resume() async {
    if (_current == null) return;
    try {
      await _player.play();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> stop() async {
    _connectTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    _current = null;
    _currentIndex = -1;
    _loading = false;
    _error = null;
    _icyTitle = '';
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> next() async {
    final list = availableStations;
    if (list.isEmpty) return;
    final idx = (_currentIndex + 1) % list.length;
    await play(list[idx]);
  }

  Future<void> previous() async {
    final list = availableStations;
    if (list.isEmpty) return;
    final idx = _currentIndex <= 0 ? list.length - 1 : _currentIndex - 1;
    await play(list[idx]);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _icySub?.cancel();
    _connectTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}