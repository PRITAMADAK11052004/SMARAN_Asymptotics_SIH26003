import 'package:flutter/material.dart';

import '../../core/theme/caregiver_theme.dart';

class FamilyHelpScreen extends StatelessWidget {
  const FamilyHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Help & Support',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 4),
          const Text('We are here for you',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 18),

          _tile(Icons.help_outline_rounded, 'FAQs',
              'Find answers to common questions'),
          const SizedBox(height: 10),
          _tile(Icons.headset_mic_rounded, 'Contact Support',
              'Get in touch with our team'),
          const SizedBox(height: 10),
          _tile(Icons.emergency_rounded, 'Emergency Guidance',
              'What to do in an emergency'),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: CG.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Family Support is not Emergency medical care. '
                    'In case of a medical emergency, please contact '
                    'local emergency services or a doctor.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CG.primary.withValues(alpha: 0.9),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CG.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: CG.textPrimary)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: CG.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: CG.textFaint, size: 22),
        ],
      ),
    );
  }
}