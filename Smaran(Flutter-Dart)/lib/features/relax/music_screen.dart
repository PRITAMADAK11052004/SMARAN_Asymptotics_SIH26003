import 'package:flutter/material.dart';

import '../../core/data/ner_radio_stations.dart';
import '../../core/services/radio_player_service.dart';
import '../../core/theme/app_theme.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _radio = RadioPlayerService.instance;
  final _api = RadioBrowserService.instance;

  @override
  void initState() {
    super.initState();
    _radio.addListener(_rebuild);
    _api.addListener(_rebuild);
  }

  @override
  void dispose() {
    _radio.removeListener(_rebuild);
    _api.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: const Text(
          'Radio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: _radio.hasStation
            ? _FullScreenPlayer(radio: _radio)
            : _StationList(
                stations: _api.stations,
                isLoading: _api.isLoading,
                onSelect: (station) => _radio.play(station),
                onRefresh: () => _api.refresh(),
              ),
      ),
    );
  }
}

// =============================================================================
// FULL-SCREEN PLAYER
// =============================================================================

class _FullScreenPlayer extends StatelessWidget {
  final RadioPlayerService radio;
  const _FullScreenPlayer({required this.radio});

  String _statusText() {
    if (radio.hasError) return 'Could not connect';
    if (radio.isLoading) return 'Connecting…';
    if (radio.isPlaying) return 'Radio is playing';
    return 'Radio is paused';
  }

  Color _statusColor() {
    if (radio.hasError) return cDanger;
    if (radio.isLoading) return cMuted;
    if (radio.isPlaying) return cPrimaryDark;
    return cMuted;
  }

  @override
  Widget build(BuildContext context) {
    final station = radio.currentStation!;
    final playing = radio.isPlaying;
    final hasError = radio.hasError;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Big visual
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: hasError ? const Color(0xFFF6DCDD) : cSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.signal_wifi_off_rounded : Icons.radio_rounded,
              size: 70,
              color: hasError ? cDanger : cPrimaryDark,
            ),
          ),
          const SizedBox(height: 22),

          Text(
            station.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            '${station.frequency} • ${station.location}',
            style: const TextStyle(
              fontSize: 15,
              color: cMuted,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: cWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasError ? cDanger : cBorder,
                width: hasError ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (radio.isLoading && !hasError)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cMuted,
                    ),
                  )
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: hasError
                          ? cDanger
                          : (playing ? cPrimary : cMuted),
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _statusText(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _statusColor(),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Play / Pause OR Try Again
          if (hasError)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: radio.retry,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: cPrimaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              width: 110,
              height: 110,
              child: Material(
                color: cPrimaryDark,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: cPrimaryDark.withValues(alpha: 0.30),
                child: InkWell(
                  onTap: radio.togglePlayPause,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              playing ? 'PAUSE' : 'PLAY',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: cPrimaryDark,
              ),
            ),
          ],

          const Spacer(flex: 2),

          // Prev / Next
          if (!hasError)
            Row(
              children: [
                Expanded(
                  child: _NavButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Previous',
                    onTap: radio.previous,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Next',
                    onTap: radio.next,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Choose another station
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: radio.stop,
              icon: const Icon(
                Icons.list_rounded,
                size: 22,
                color: cPrimaryDark,
              ),
              label: const Text(
                'Choose another station',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: cPrimaryDark, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cWhite,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: const Color(0x1A7A694E),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: cPrimaryDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STATION LIST
// =============================================================================

class _StationList extends StatelessWidget {
  final List<RadioStation> stations;
  final bool isLoading;
  final void Function(RadioStation) onSelect;
  final VoidCallback onRefresh;

  const _StationList({
    required this.stations,
    required this.isLoading,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && stations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: cPrimaryDark),
      );
    }

    if (stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.radio_rounded,
                size: 64,
                color: cPrimaryDark,
              ),
              const SizedBox(height: 12),
              const Text(
                'No stations available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cDeep,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StationCard(
            station: station,
            onTap: () => onSelect(station),
          ),
        );
      },
    );
  }
}

class _StationCard extends StatelessWidget {
  final RadioStation station;
  final VoidCallback onTap;

  const _StationCard({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0x1A7A694E),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(station.logoColorValue).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  station.initials,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: cPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: cText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: cMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: cSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 26,
                  color: cPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}