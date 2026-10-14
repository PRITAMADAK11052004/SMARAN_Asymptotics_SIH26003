import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';

class CaregiverReportsScreen extends StatelessWidget {
  final SmaranStore store;
  const CaregiverReportsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final games = CaregiverAnalytics.gamesPlayedThisWeek(store);
    final (done, total) = CaregiverAnalytics.remindersToday(store);
    final compliance = CaregiverAnalytics.reminderCompliancePercent(store);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Care Report',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: CG.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text('20 Sep 2025 – 26 Sep 2025',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: '$games',
                  label: 'Games This Week',
                  bg: CG.gamesBg,
                  fg: CG.gamesFg,
                  icon: Icons.sports_esports_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$compliance%',
                  label: 'Reminder Compliance',
                  bg: CG.medicineBg,
                  fg: CG.medicineFg,
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: '$done/$total',
                  label: 'Meds Today',
                  bg: CG.hydrationBg,
                  fg: CG.hydrationFg,
                  icon: Icons.medication_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '${store.hydrationToday()}/${store.hydrationTarget}',
                  label: 'Hydration',
                  bg: CG.moodBg,
                  fg: CG.moodFg,
                  icon: Icons.local_drink_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _download(context),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Download Report (PDF)',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: CG.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _download(context),
              icon: const Icon(Icons.share_rounded,
                  size: 20, color: CG.primary),
              label: const Text(
                'Share with Doctor',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: CG.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CG.primary, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final patients = AuthStore.instance.linkedPatients;
    final caregiver = AuthStore.instance.currentUser;
    if (patients.isEmpty || caregiver == null) return;

    final p = patients.first;
    final games = CaregiverAnalytics.gamesPlayedThisWeek(store);
    final compliance = CaregiverAnalytics.reminderCompliancePercent(store);
    final (done, total) = CaregiverAnalytics.remindersToday(store);
    final streak = CaregiverAnalytics.dailyStreak(store);
    final mood = CaregiverAnalytics.moodLabel(store);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SMARAN — WEEKLY CARE REPORT',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Generated: ${DateTime.now()}',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 10),
            _kv('Patient', p.fullName),
            _kv('Patient ID', p.patientId ?? '—'),
            _kv('Caregiver', caregiver.fullName),
            pw.SizedBox(height: 18),
            pw.Text('Summary',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _kv('Games this week', '$games'),
            _kv('Daily streak', '$streak days'),
            _kv('Reminder compliance', '$compliance%'),
            _kv('Medicines today', '$done / $total'),
            _kv('Hydration today',
                '${store.hydrationToday()}/${store.hydrationTarget}'),
            _kv('Current mood', mood),
            pw.SizedBox(height: 26),
            pw.Text(
              'This report is generated by Smaran and is intended for '
              'care coordination. It is not a medical diagnosis.',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name:
          'smaran_${p.fullName.replaceAll(' ', '_').toLowerCase()}.pdf',
    );
  }

  pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 160,
              child: pw.Text(k,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
            ),
            pw.Expanded(
              child: pw.Text(v,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      );
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  const _MetricTile({
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}