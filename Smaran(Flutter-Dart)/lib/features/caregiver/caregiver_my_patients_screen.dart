import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';
import '../auth/link_patient_screen.dart';

class CaregiverMyPatientsScreen extends StatefulWidget {
  final SmaranStore store;
  final VoidCallback onOpenProfile;
  const CaregiverMyPatientsScreen({
    super.key,
    required this.store,
    required this.onOpenProfile,
  });

  @override
  State<CaregiverMyPatientsScreen> createState() =>
      _CaregiverMyPatientsScreenState();
}

class _CaregiverMyPatientsScreenState
    extends State<CaregiverMyPatientsScreen> {
  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _addPatient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LinkPatientScreen(showBackButton: true),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _unlink(AppUser patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Unlink this patient?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: CG.primary)),
        content: Text(
          'You will no longer be able to monitor ${patient.fullName}.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CG.danger),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    if (patient.patientId == null) return;

    try {
      await AuthStore.instance.unlinkPatientById(patient.patientId!);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not unlink: $e'),
              backgroundColor: CG.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patients = AuthStore.instance.linkedPatients;
    final canAddMore = patients.length < 10;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Patients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: CG.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${patients.length} of 10 linked',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CG.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: canAddMore ? _addPatient : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add',
                        style: TextStyle(
                            fontWeight: FontWeight.w900)),
                    style: FilledButton.styleFrom(
                      backgroundColor: CG.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (patients.isEmpty)
                _emptyState()
              else
                ...patients.map((p) => _PatientCard(
                      patient: p,
                      onOpen: widget.onOpenProfile,
                      onUnlink: () => _unlink(p),
                    )),

              if (!canAddMore) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CG.primaryPale,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'You have reached the maximum of 10 patients.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: CG.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded,
              size: 54, color: CG.primary),
          const SizedBox(height: 12),
          const Text(
            'No patients linked yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: CG.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Add" and scan the patient\'s Smaran QR to start monitoring.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: CG.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final AppUser patient;
  final VoidCallback onOpen;
  final VoidCallback onUnlink;

  const _PatientCard({
    required this.patient,
    required this.onOpen,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CG.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: CG.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    patient.fullName.isNotEmpty
                        ? patient.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: CG.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: CG.textPrimary,
                        ),
                      ),
                      if (patient.patientId != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          patient.patientId!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: CG.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: patient.verified
                                  ? CG.success
                                  : CG.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            patient.verified ? 'Verified' : 'Pending',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: patient.verified
                                  ? CG.primary
                                  : CG.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Unlink',
                  onPressed: onUnlink,
                  icon: const Icon(Icons.link_off_rounded,
                      color: CG.danger, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}