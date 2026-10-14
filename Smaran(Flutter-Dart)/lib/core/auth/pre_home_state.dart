/// Tracks where the user is in the pre-home onboarding flow.
/// Persisted so closing the app mid-flow resumes correctly.
enum OnboardingPhase {
  none,          // fresh app, nothing started
  login,         // login screen
  registration,  // filling registration form
  otpMethod,     // choosing SMS vs Email
  otpEntry,      // entering 6-digit OTP
  faceSetup,     // patient only — one-time face enrollment
  smrnReveal,    // patient only — SMRN ID + QR reveal
  linkPrompt,    // caregiver/family — link patient
  home,          // fully onboarded, ready for Home
}

extension OnboardingPhaseX on OnboardingPhase {
  String get key => name;

  static OnboardingPhase fromKey(String? k) {
    if (k == null) return OnboardingPhase.none;
    return OnboardingPhase.values.firstWhere(
      (e) => e.name == k,
      orElse: () => OnboardingPhase.none,
    );
  }
}