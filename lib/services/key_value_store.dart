/// Tiny persistence contract so state can be tested without a device.
abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Keeps everything in memory. Used by tests and the DartPad preview.
class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : data = {...?initial};

  final Map<String, String> data;

  @override
  String? getString(String key) => data[key];

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}
