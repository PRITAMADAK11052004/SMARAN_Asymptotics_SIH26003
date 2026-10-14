import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/caregiver_theme.dart';

class SmaranIdCard extends StatefulWidget {
  final String smrnId;
  final double size;
  final bool startWithQr;

  const SmaranIdCard({
    super.key,
    required this.smrnId,
    this.size = 220,
    this.startWithQr = true,
  });

  @override
  State<SmaranIdCard> createState() => _SmaranIdCardState();
}

class _SmaranIdCardState extends State<SmaranIdCard> {
  late bool _showQr = widget.startWithQr;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showQr = !_showQr),
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CG.primary, width: 2),
          boxShadow: CG.cardShadow,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _showQr ? _qrView() : _idView(),
        ),
      ),
    );
  }

  Widget _qrView() {
    return Column(
      key: const ValueKey('qr'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: QrImageView(
              data: widget.smrnId,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: CG.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: CG.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Tap to show ID',
            style: TextStyle(
              fontSize: 10.5,
              color: CG.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _idView() {
    // Scale fonts with widget size so nothing overflows.
    final scale = (widget.size / 220).clamp(0.5, 1.4);
    final iconSize = (34 * scale).clamp(20.0, 40.0);
    final idSize = (20 * scale).clamp(12.0, 24.0);
    final labelSize = (10.5 * scale).clamp(8.0, 12.0);

    return Column(
      key: const ValueKey('id'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.badge_rounded, color: CG.primary, size: iconSize),
        SizedBox(height: 10 * scale),
        Text(
          'SMARAN ID',
          style: TextStyle(
            fontSize: labelSize,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: CG.textMuted,
          ),
        ),
        SizedBox(height: 8 * scale),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              widget.smrnId,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: idSize,
                fontWeight: FontWeight.w900,
                color: CG.primary,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        SizedBox(height: 10 * scale),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Tap to show QR',
            style: TextStyle(
              fontSize: labelSize,
              color: CG.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}