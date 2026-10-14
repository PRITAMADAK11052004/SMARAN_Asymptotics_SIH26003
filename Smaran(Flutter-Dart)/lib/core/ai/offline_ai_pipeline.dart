import '../domain/smaran_models.dart';

abstract interface class SpeechRecognizer {
  Future<String> transcribe(List<int> audioBytes, {required String language});
}

abstract interface class Translator {
  Future<String> translate(
    String text, {
    required String from,
    required String to,
  });
}

abstract interface class LocalLanguageModel {
  Future<String> generate(String prompt, {required PatientContext context});
}

abstract interface class SpeechSynthesizer {
  Future<void> speak(String text, {required String language});
}

class OfflineAiPipeline {
  final SpeechRecognizer asr;
  final Translator translator;
  final LocalLanguageModel languageModel;
  final SpeechSynthesizer tts;

  const OfflineAiPipeline({
    required this.asr,
    required this.translator,
    required this.languageModel,
    required this.tts,
  });

  Future<String> respond({
    required List<int> audioBytes,
    required String regionalLanguage,
    required PatientContext context,
  }) async {
    final regionalText = await asr.transcribe(
      audioBytes,
      language: regionalLanguage,
    );
    final englishInput = await translator.translate(
      regionalText,
      from: regionalLanguage,
      to: 'English',
    );
    final englishResponse = await languageModel.generate(
      englishInput,
      context: context,
    );
    final regionalResponse = await translator.translate(
      englishResponse,
      from: 'English',
      to: regionalLanguage,
    );
    await tts.speak(regionalResponse, language: regionalLanguage);
    return regionalResponse;
  }
}

class OfflineFallbackTranslator implements Translator {
  @override
  Future<String> translate(
    String text, {
    required String from,
    required String to,
  }) async => text;
}

class OfflineFallbackLanguageModel implements LocalLanguageModel {
  @override
  Future<String> generate(
    String prompt, {
    required PatientContext context,
  }) async {
    final nextReminder = context.reminders.where((item) => !item.isCompleted);
    if (nextReminder.isNotEmpty) {
      final reminder = nextReminder.first;
      return 'Your next routine is ${reminder.medicationName}. You are safe and supported.';
    }
    return 'I am here with you. We can take one calm step at a time.';
  }
}