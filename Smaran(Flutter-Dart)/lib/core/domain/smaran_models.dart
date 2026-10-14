enum UserRole { patient, family, caregiver }

enum SyncStatus { pending, syncing, synced, failed }

class PatientProfile {
  final String id;
  final String name;
  final String languagePreference;
  final String emergencyContact;

  const PatientProfile({
    required this.id,
    required this.name,
    required this.languagePreference,
    required this.emergencyContact,
  });
}

class GameHistory {
  final String gameId;
  final int score;
  final Map<String, Object?> metrics;
  final int difficultyLevel;
  final DateTime timestamp;

  const GameHistory({
    required this.gameId,
    required this.score,
    required this.metrics,
    required this.difficultyLevel,
    required this.timestamp,
  });
}

class InteractionLog {
  final String inputType;
  final Map<String, double> extractedFeatures;
  final bool patternChangeDetected;
  final DateTime timestamp;

  const InteractionLog({
    required this.inputType,
    required this.extractedFeatures,
    required this.patternChangeDetected,
    required this.timestamp,
  });
}

class ReminderRecord {
  final String id;
  final String medicationName;
  final DateTime time;
  final bool isCompleted;
  final SyncStatus syncStatus;

  const ReminderRecord({
    required this.id,
    required this.medicationName,
    required this.time,
    required this.isCompleted,
    required this.syncStatus,
  });
}

class FaceEmbedding {
  final String personName;
  final String relationship;
  final List<double> embeddingVector;
  final String photoPath;

  const FaceEmbedding({
    required this.personName,
    required this.relationship,
    required this.embeddingVector,
    required this.photoPath,
  });
}

class SystemLog {
  final String syncQueueId;
  final String payloadJson;
  final SyncStatus status;

  const SystemLog({
    required this.syncQueueId,
    required this.payloadJson,
    required this.status,
  });
}

class PatientContext {
  final PatientProfile profile;
  final List<GameHistory> recentGames;
  final List<ReminderRecord> reminders;
  final List<String> behavioralSignals;

  const PatientContext({
    required this.profile,
    this.recentGames = const [],
    this.reminders = const [],
    this.behavioralSignals = const [],
  });
}