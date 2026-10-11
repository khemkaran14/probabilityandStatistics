/// Opens the system share sheet.
abstract class ShareService {
  Future<void> shareText(String text);
}

/// Records what would have been shared. Used by tests and DartPad.
class FakeShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}
