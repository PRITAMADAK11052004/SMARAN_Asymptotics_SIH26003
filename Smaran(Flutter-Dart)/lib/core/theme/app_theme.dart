import 'package:flutter/material.dart';

const cBg = Color(0xFFFFF6E3);
const cWhite = Color(0xFFFFFDFC);
const cPrimary = Color(0xFF18B981);
const cPrimaryDark = Color(0xFF4F743D);
const cDeep = Color(0xFF193C34);
const cSoft = Color(0xFFE5F0D8);
const cMint = Color(0xFFEEF4E7);
const cTeal = Color(0xFF2E7D68);
const cText = Color(0xFF26332E);
const cMuted = Color(0xFF6D746E);
const cBorder = Color(0xFFE6DED0);
const cDanger = Color(0xFFC64A4A);

InputDecoration inputDec(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );

Widget primaryButton(String text, VoidCallback? onPressed, {IconData? icon}) => SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cPrimaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
    );

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 58});
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const PageHeader({super.key, required this.title, this.subtitle = ''});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cDeep)),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: cMuted)),
          ],
        ),
      );
}
