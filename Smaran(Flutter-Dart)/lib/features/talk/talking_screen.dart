import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/ai/voice_reminder_parser.dart';
import '../../core/domain/app_models.dart';
import '../../core/localization/app_languages.dart';
import '../../core/theme/app_theme.dart';

/// Voice interaction with Smaran.
///
/// - Patient does NOT need to pick a language first.
/// - We start STT with the system default locale.
/// - After STT produces text, we detect the script and switch TTS.
/// - A small "Language" chip in the corner lets the patient override
///   if the system gets it wrong.
class TalkingScreen extends StatefulWidget {
  const TalkingScreen({super.key});

  @override
  State<TalkingScreen> createState() => _TalkingScreenState();
}

enum _VoiceState { idle, listening, processing, success, error }

class _TalkingScreenState extends State<TalkingScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _manualInput = TextEditingController();
  final FlutterTts _tts = FlutterTts();

  _VoiceState _state = _VoiceState.idle;
  String _transcript = '';
  AlarmReminder? _parsed;
  String? _queryAnswer;
  String? _error;

  /// Detected language. Starts as English but auto-switches after each
  /// utterance based on the Unicode script of the transcript.
  late AppLanguage _detectedLanguage;

  @override
  void initState() {
    super.initState();
    _detectedLanguage = AppLanguage.english;
    _initSpeech();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.43);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _state = _VoiceState.error;
            _error = 'Sorry, I did not understand.';
          });
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (_state == _VoiceState.listening) {
              setState(() => _state = _VoiceState.processing);
            }
          }
        },
      );
    } catch (_) {}
  }

  /// Detect the language from the Unicode range of the transcript.
  ///
  /// This is a lightweight but effective heuristic:
  ///   - Bengali script   → Assamese or Bengali
  ///   - Devanagari       → Hindi or Nepali
  ///   - Meitei Mayek     → Meitei
  ///   - Latin script     → English / Mizo / Khasi / Garo / Nagamese
  AppLanguage _detectScript(String text) {
    if (text.isEmpty) return AppLanguage.english;

    final hasBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(text);
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    final hasMeitei = RegExp(r'[\uABC0-\uABFF]').hasMatch(text);

    if (hasMeitei) return AppLanguage.meitei;
    if (hasBengali) {
      // Bengali and Assamese share the same script.
      // Distinguish by common Assamese-only words if present.
      if (text.contains('আছ') ||
          text.contains('কৰ') ||
          text.contains('নাই') ||
          text.contains('মই')) {
        return AppLanguage.assamese;
      }
      return AppLanguage.bengali;
    }
    if (hasDevanagari) {
      // Nepali-specific words vs Hindi.
      if (text.contains('छ') || text.contains('हो') || text.contains('गर्न')) {
        return AppLanguage.nepali;
      }
      return AppLanguage.hindi;
    }
    // Default to English for Latin scripts
    return AppLanguage.english;
  }

  Future<void> _speak(String text, AppLanguage lang) async {
    try {
      await _tts.setLanguage(lang.localeCode);
      await _tts.speak(text);
    } catch (_) {
      try {
        await _tts.setLanguage('en-IN');
        await _tts.speak(text);
      } catch (_) {}
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _state = _VoiceState.listening;
      _error = null;
      _parsed = null;
      _queryAnswer = null;
      _transcript = '';
    });

    final ok = await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult && _transcript.trim().isNotEmpty) {
          _handleTranscript(_transcript);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        // No localeId → uses the device's system locale.
        // This gives us the best shot at auto-handling.
      ),
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _state = _VoiceState.error;
        _error = 'Please allow microphone access.';
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    if (_transcript.trim().isNotEmpty) {
      _handleTranscript(_transcript);
    } else {
      setState(() => _state = _VoiceState.idle);
    }
  }

  Future<void> _handleTranscript(String text) async {
    // Auto-detect language from the script.
    final detected = _detectScript(text);
    if (detected != _detectedLanguage) {
      setState(() => _detectedLanguage = detected);
    }

    setState(() => _state = _VoiceState.processing);

    // Try Q&A first
    final answer = VoiceQueryHandler.respond(
      transcript: text,
      reminders: const [],
      language: detected.englishName,
    );

    if (answer != null) {
      setState(() {
        _queryAnswer = answer;
        _state = _VoiceState.success;
      });
      await _speak(answer, detected);
      return;
    }

    // Try alarm parse
    final result = VoiceReminderParser.parse(
      text,
      nextId: DateTime.now().microsecondsSinceEpoch.remainder(2147483647),
      languageKey: detected.key,
    );

    setState(() {
      if (result == null) {
        _state = _VoiceState.error;
        _error = "Sorry, I didn't understand. Please try again.";
        _parsed = null;
      } else {
        _parsed = result;
        _state = _VoiceState.success;
      }
      _queryAnswer = null;
    });
  }

  void _confirm() {
    if (_parsed == null) return;
    Navigator.pop(context, _parsed);
  }

  void _reset() {
    setState(() {
      _state = _VoiceState.idle;
      _transcript = '';
      _parsed = null;
      _queryAnswer = null;
      _error = null;
    });
  }

  Future<void> _showLanguagePicker() async {
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: cBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Speaking language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cDeep,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppLanguage.values.map((lang) {
                    final selected = _detectedLanguage == lang;
                    return ChoiceChip(
                      label: Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : cText,
                        ),
                      ),
                      selected: selected,
                      selectedColor: cPrimaryDark,
                      backgroundColor: cWhite,
                      onSelected: (_) => Navigator.pop(ctx, lang),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _detectedLanguage = picked);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _manualInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cDeep, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Talk to Smaran',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              // Small optional language chip
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _showLanguagePicker,
                  icon: const Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: cPrimaryDark,
                  ),
                  label: Text(
                    _detectedLanguage.nativeName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: cPrimaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Smaran visual
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: cSoft,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cPrimaryDark.withValues(alpha: 0.08),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 64,
                  color: cPrimaryDark,
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'How can I help you?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: cDeep,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap and speak naturally',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: cMuted),
              ),

              const SizedBox(height: 32),

              // Mic button
              _MicButton(
                state: _state,
                onTap: _state == _VoiceState.listening
                    ? _stopListening
                    : _startListening,
              ),

              const SizedBox(height: 16),

              // Status text
              Text(
                _statusTextFor(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _state == _VoiceState.error ? cDanger : cMuted,
                  height: 1.4,
                ),
              ),

              // Transcript
              if (_transcript.isNotEmpty &&
                  _state != _VoiceState.listening) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You said:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _transcript,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Q&A answer
              if (_queryAnswer != null) ...[
                const SizedBox(height: 14),
                _AnswerCard(
                  answer: _queryAnswer!,
                  onSpeakAgain: () =>
                      _speak(_queryAnswer!, _detectedLanguage),
                ),
              ],

              // Parsed alarm preview
              if (_parsed != null) ...[
                const SizedBox(height: 14),
                _PreviewCard(reminder: _parsed!),
              ],

              // Error card
              if (_state == _VoiceState.error && _error != null) ...[
                const SizedBox(height: 14),
                _ErrorCard(
                  message: _error!,
                  onRetry: _reset,
                ),
              ],

              const SizedBox(height: 24),

              // Add alarm button (only when parsed)
              if (_parsed != null)
                primaryButton(
                  'Set Reminder',
                  _confirm,
                  icon: Icons.alarm_add_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusTextFor() {
    switch (_state) {
      case _VoiceState.idle:
        return 'TAP TO SPEAK';
      case _VoiceState.listening:
        return 'Listening…';
      case _VoiceState.processing:
        return 'Understanding…';
      case _VoiceState.success:
        return 'Done';
      case _VoiceState.error:
        return "Sorry, I didn't understand.";
    }
  }
}

// =============================================================================
// MIC BUTTON — one large tap target
// =============================================================================

class _MicButton extends StatelessWidget {
  final _VoiceState state;
  final VoidCallback onTap;

  const _MicButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final listening = state == _VoiceState.listening;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: listening ? cDanger : cPrimaryDark,
          boxShadow: [
            BoxShadow(
              color: (listening ? cDanger : cPrimaryDark)
                  .withValues(alpha: 0.30),
              blurRadius: listening ? 40 : 20,
              spreadRadius: listening ? 10 : 2,
            ),
          ],
        ),
        child: Icon(
          listening ? Icons.stop_rounded : Icons.mic_rounded,
          size: 70,
          color: Colors.white,
        ),
      ),
    );
  }
}

// =============================================================================
// ANSWER CARD
// =============================================================================

class _AnswerCard extends StatelessWidget {
  final String answer;
  final VoidCallback onSpeakAgain;

  const _AnswerCard({required this.answer, required this.onSpeakAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cPrimaryDark, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over_rounded,
                  color: cPrimaryDark, size: 20),
              SizedBox(width: 8),
              Text(
                'Smaran says',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cDeep,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSpeakAgain,
              icon: const Icon(
                Icons.volume_up_rounded,
                color: cPrimaryDark,
                size: 20,
              ),
              label: const Text(
                'Hear again',
                style: TextStyle(
                  color: cPrimaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ERROR CARD
// =============================================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cDanger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cDanger,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: cDanger),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: cDanger,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PARSED PREVIEW
// =============================================================================

class _PreviewCard extends StatelessWidget {
  final AlarmReminder reminder;
  const _PreviewCard({required this.reminder});

  String get _typeLabel => switch (reminder.alarmType) {
        AlarmType.medicine => 'Medicine',
        AlarmType.food => 'Food',
        AlarmType.memoryActivity => 'Memory Activity',
        AlarmType.customTask => 'Specific Task',
      };

  String get _medicineLabel =>
      reminder.medicineTiming == MedicineTiming.beforeFood
          ? ' • Before food'
          : reminder.medicineTiming == MedicineTiming.afterFood
              ? ' • After food'
              : '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cPrimaryDark, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: cPrimaryDark, size: 22),
              SizedBox(width: 8),
              Text(
                'Understood',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reminder.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${reminder.hour.toString().padLeft(2, '0')}:'
            '${reminder.minute.toString().padLeft(2, '0')} ${reminder.amPm}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: cPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_typeLabel$_medicineLabel • ${reminder.repeatType.name}',
            style: const TextStyle(fontSize: 12, color: cMuted),
          ),
        ],
      ),
    );
  }
}