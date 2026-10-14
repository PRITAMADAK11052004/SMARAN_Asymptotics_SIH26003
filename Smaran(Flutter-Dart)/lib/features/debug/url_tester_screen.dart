
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';

/// DEBUG-ONLY screen.
///
/// Lets you paste any stream URL and test it directly with just_audio.
/// Shows the exact error message if it fails.
class UrlTesterScreen extends StatefulWidget {
  const UrlTesterScreen({super.key});

  @override
  State<UrlTesterScreen> createState() => _UrlTesterScreenState();
}

class _UrlTesterScreenState extends State<UrlTesterScreen> {
  final _urlCtrl = TextEditingController(
    text: 'https://air.pc.cdn.bitgravity.com/air/live/pbaudio001/playlist.m3u8',
  );
  final _player = AudioPlayer();

  String _status = 'Idle';
  String _error = '';
  bool _isPlaying = false;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _status = 'Trying…';
      _error = '';
      _loading = true;
      _isPlaying = false;
    });

    try {
      await _player.stop();
      await _player.setUrl(url);

      setState(() => _status = 'Loaded. Waiting for playback…');

      unawaited(_player.play());

      // Wait up to 30 seconds for actual playback
      final ok = await _waitForPlayback(const Duration(seconds: 30));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _isPlaying = ok;
        _status = ok
            ? '✅ PLAYING — this URL works!'
            : '❌ Loaded but no audio came through';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isPlaying = false;
        _status = '❌ FAILED';
        _error = e.toString();
      });
    }
  }

  Future<bool> _waitForPlayback(Duration timeout) async {
    try {
      await _player.playerStateStream
          .firstWhere((s) =>
              s.playing && s.processingState == ProcessingState.ready)
          .timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _status = 'Stopped';
      _isPlaying = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: const Text(
          'URL Tester (Debug)',
          style: TextStyle(fontWeight: FontWeight.w900, color: cDeep),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste any radio stream URL below and tap Test.',
                style: TextStyle(fontSize: 14, color: cMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: inputDec('Stream URL'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _test,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Test',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        style: FilledButton.styleFrom(
                          backgroundColor: cPrimaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cDanger,
                        side: const BorderSide(color: cDanger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: cMuted)),
                    const SizedBox(height: 6),
                    Text(_status,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: cText)),
                    if (_isPlaying) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'The audio is playing right now.',
                        style: TextStyle(
                            fontSize: 13,
                            color: cPrimaryDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Error message',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: cDanger)),
                      const SizedBox(height: 4),
                      SelectableText(
                        _error,
                        style: const TextStyle(
                          fontSize: 12,
                          color: cDanger,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to test a URL',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: cPrimaryDark)),
                    SizedBox(height: 8),
                    Text(
                      '1. Open Chrome on your phone\n'
                      '2. Go to newsonair.gov.in\n'
                      '3. Start any live radio stream\n'
                      '4. Right-click → Inspect → Network tab\n'
                      '5. Filter by ".m3u8"\n'
                      '6. Copy the full URL\n'
                      '7. Paste above and tap Test',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: cPrimaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}