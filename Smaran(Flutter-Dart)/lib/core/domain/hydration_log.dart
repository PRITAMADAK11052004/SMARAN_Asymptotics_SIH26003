class HydrationLog {
  final DateTime timestamp;
  final int glasses;

  HydrationLog({required this.timestamp, required this.glasses});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'glasses': glasses,
      };

  factory HydrationLog.fromJson(Map<String, dynamic> j) => HydrationLog(
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            (j['timestamp'] as num?)?.toInt() ??
                DateTime.now().millisecondsSinceEpoch),
        glasses: (j['glasses'] as num?)?.toInt() ?? 0,
      );
}