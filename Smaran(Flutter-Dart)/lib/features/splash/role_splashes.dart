import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/theme/caregiver_theme.dart';

/// Base splash — shared chrome for gradient variants (Caregiver/Family).
class _SplashBase extends StatefulWidget {
  final List<Color> gradient;
  final String tagline;
  final String? subtitle;
  final VoidCallback onDone;
  final Duration holdFor;

  const _SplashBase({
    required this.gradient,
    required this.tagline,
    required this.onDone,
    this.subtitle,
    this.holdFor = const Duration(milliseconds: 1800),
  });

  @override
  State<_SplashBase> createState() => _SplashBaseState();
}

class _SplashBaseState extends State<_SplashBase>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();

    Future.delayed(widget.holdFor, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 78,
                        height: 78,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.eco_rounded,
                          color: CG.primary,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Smaran',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1. Default Smaran splash — neutral, cream, no role identity.
class DefaultSplash extends StatefulWidget {
  final VoidCallback onDone;
  const DefaultSplash({super.key, required this.onDone});

  @override
  State<DefaultSplash> createState() => _DefaultSplashState();
}

class _DefaultSplashState extends State<DefaultSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.eco_rounded,
                    color: CG.primary,
                    size: 90,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smaran',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ek ehsaas, yaadon ke paas',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: CG.textMuted,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(CG.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. Patient splash — full-screen Durga Puja artwork + dhaak audio.
class PatientSplash extends StatefulWidget {
  final VoidCallback onDone;
  const PatientSplash({super.key, required this.onDone});

  @override
  State<PatientSplash> createState() => _PatientSplashState();
}

class _PatientSplashState extends State<PatientSplash> {
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();

    // Preload the image so there's no flicker on slow devices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/durga-puja-splash.png'),
        context,
      );
    });

    _playAudio();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onDone();
    });
  }

  Future<void> _playAudio() async {
    try {
      _player = AudioPlayer();
      await _player!.setVolume(0.85);
      await _player!.play(AssetSource('audio/patient_splash_dhaak.mp3'));
    } catch (_) {
      // Audio missing or unsupported → silent splash.
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1A1A),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/durga-puja-splash.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFF8B1A1A),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_rounded,
                      color: Colors.white, size: 90),
                  SizedBox(height: 20),
                  Text(
                    'Smaran',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'ek ehsaas, yaadon ke paas',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3. Caregiver splash — teal + medical green.
class CaregiverSplash extends StatelessWidget {
  final VoidCallback onDone;
  const CaregiverSplash({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return _SplashBase(
      gradient: const [
        Color(0xFF12463C),
        Color(0xFF2D6A4F),
        Color(0xFF7FB89D),
      ],
      tagline: 'caring hands, guiding hearts',
      subtitle: 'CAREGIVER MODE',
      onDone: onDone,
      holdFor: const Duration(milliseconds: 1800),
    );
  }
}

/// 4. Family splash — warm terracotta + orange.
class FamilySplash extends StatelessWidget {
  final VoidCallback onDone;
  const FamilySplash({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return _SplashBase(
      gradient: const [
        Color(0xFF8A3A1E),
        Color(0xFFC25A2A),
        Color(0xFFF0A868),
      ],
      tagline: 'together, we remember',
      subtitle: 'FAMILY MODE',
      onDone: onDone,
      holdFor: const Duration(milliseconds: 1800),
    );
  }
}

/// Factory — returns the splash for the given role.
Widget roleSplash(UserRole role, VoidCallback onDone) {
  switch (role) {
    case UserRole.patient:
      return PatientSplash(onDone: onDone);
    case UserRole.caregiver:
      return CaregiverSplash(onDone: onDone);
    case UserRole.family:
      return FamilySplash(onDone: onDone);
  }
}