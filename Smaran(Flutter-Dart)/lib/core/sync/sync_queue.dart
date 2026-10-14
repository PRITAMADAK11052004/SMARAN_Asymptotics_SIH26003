import '../domain/smaran_models.dart';

class SyncQueueItem {
  final String id;
  final String tableName;
  final String payloadJson;
  SyncStatus status;

  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.payloadJson,
    this.status = SyncStatus.pending,
  });
}

abstract interface class SyncTransport {
  Future<void> send(SyncQueueItem item);
}

class OfflineFirstSyncQueue {
  final List<SyncQueueItem> _items = [];

  List<SyncQueueItem> get pendingItems => List.unmodifiable(
        _items.where((item) => item.status == SyncStatus.pending),
      );

  void enqueue(SyncQueueItem item) => _items.add(item);

  Future<void> flush(SyncTransport transport, {required bool online}) async {
    if (!online) return;
    for (final item in pendingItems) {
      item.status = SyncStatus.syncing;
      try {
        await transport.send(item);
        item.status = SyncStatus.synced;
      } catch (_) {
        item.status = SyncStatus.failed;
      }
    }
  }
}