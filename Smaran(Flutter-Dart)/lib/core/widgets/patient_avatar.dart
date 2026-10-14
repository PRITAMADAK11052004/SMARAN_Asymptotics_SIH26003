import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import '../theme/caregiver_theme.dart';

/// A reusable avatar that shows the patient's enrolled face photo
/// if available, or their initials as a fallback.
class PatientAvatar extends StatelessWidget {
  final AppUser? user;
  final String? photoBase64;
  final String fallbackName;
  final double size;
  final bool circle;
  final Color? borderColor;
  final VoidCallback? onTap;

  const PatientAvatar({
    super.key,
    this.user,
    this.photoBase64,
    required this.fallbackName,
    this.size = 56,
    this.circle = true,
    this.borderColor,
    this.onTap,
  });

  String? get _resolvedPhoto => photoBase64 ?? user?.facePhotoBase64;

  String get _initial {
    final name = user?.fullName ?? fallbackName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final photo = _resolvedPhoto;

    final content = (photo == null || photo.isEmpty)
        ? _initials()
        : _photo(photo);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (photo == null || photo.isEmpty)
              ? CG.primarySoft
              : Colors.transparent,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(size * 0.28),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 2)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }

  Widget _initials() => Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: CG.primary,
          ),
        ),
      );

  Widget _photo(String base64) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(base64);
    } catch (_) {
      return _initials();
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => _initials(),
      gaplessPlayback: true,
    );
  }
}

/// Fullscreen viewer for the patient photo — used when tapping the avatar.
Future<void> showPatientPhotoViewer(
  BuildContext context, {
  required String base64Jpeg,
  required String patientName,
}) {
  Uint8List? bytes;
  try {
    bytes = base64Decode(base64Jpeg);
  } catch (_) {
    return Future.value();
  }

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: CG.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(
              bytes!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patientName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            label: const Text(
              'Close',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}