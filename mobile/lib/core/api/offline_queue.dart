import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'api_client.dart';

/// Farmer-first offline support: a POST made with no signal (e.g. creating a
/// listing from a field with no bars) is queued locally and replayed
/// automatically the moment connectivity returns. Each entry is idempotent —
/// callers should include a client-generated idempotency key in the body.
class OfflineQueue {
  static final OfflineQueue instance = OfflineQueue._internal();
  OfflineQueue._internal() {
    Connectivity().onConnectivityResult.listen((result) {
      if (result != ConnectivityResult.none) flush();
    });
  }

  Box get _box => Hive.box('pending_uploads');

  Future<void> enqueue({required String path, required Map<String, dynamic> body}) async {
    final entries = List<String>.from(_box.get('queue', defaultValue: <String>[]));
    entries.add(jsonEncode({'path': path, 'body': body, 'queuedAt': DateTime.now().toIso8601String()}));
    await _box.put('queue', entries);
  }

  Future<void> flush() async {
    final entries = List<String>.from(_box.get('queue', defaultValue: <String>[]));
    if (entries.isEmpty) return;

    final remaining = <String>[];
    for (final raw in entries) {
      final item = jsonDecode(raw) as Map<String, dynamic>;
      try {
        await ApiClient.instance.dio.post(item['path'], data: item['body']);
      } catch (_) {
        remaining.add(raw); // keep for next retry
      }
    }
    await _box.put('queue', remaining);
  }
}
