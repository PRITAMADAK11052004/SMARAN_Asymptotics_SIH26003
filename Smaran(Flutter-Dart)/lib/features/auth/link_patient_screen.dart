import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/caregiver_theme.dart';
import '../caregiver/qr_scanner_screen.dart';

class LinkPatientScreen extends StatefulWidget {
  final bool showBackButton;
  const LinkPatientScreen({super.key, this.showBackButton = false});

  @override
  State<LinkPatientScreen> createState() => _LinkPatientScreenState();
}

class _LinkPatientScreenState extends State<LinkPatientScreen> {
  final _idCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanQr());
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scanned == null || !mounted) return;
    _idCtrl.text = scanned;
    await _link(scanned);
  }

  Future<void> _link(String smrnId) async {
    setState(() => _busy = true);
    try {
      final ok = await AuthStore.instance.linkPatientBySmrnId(smrnId);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient linked successfully.'),
            backgroundColor: CG.primary,
          ),
        );
        if (widget.showBackButton) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No patient found with that ID.'),
            backgroundColor: CG.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Link failed: $e'),
            backgroundColor: CG.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CG.bg,
      appBar: AppBar(
        backgroundColor: CG.bg,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: CG.primary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Link a Patient',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: CG.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: CG.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: CG.primaryPale,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: CG.primary, size: 42),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Scan the patient's QR",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: CG.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Open the patient's Profile tab, then tap the QR code. "
                      "Use the camera to scan.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: CG.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _scanQr,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text(
                          'Open Camera Scanner',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
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
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Row(children: [
                Expanded(child: Divider(color: CG.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: CG.textMuted)),
                ),
                Expanded(child: Divider(color: CG.border)),
              ]),
              const SizedBox(height: 20),
              const Text(
                'Enter Smaran ID manually',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _idCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                ),
                decoration: inputDec('SMRN-XXXX-XXXX'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          final v = _idCtrl.text.trim().toUpperCase();
                          if (v.isEmpty) return;
                          _link(v);
                        },
                  icon: const Icon(Icons.link_rounded,
                      color: CG.primary),
                  label: const Text(
                    'Link by ID',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: CG.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CG.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: CG.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}