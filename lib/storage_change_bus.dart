/// Domain change notifications from [Storage] (and other writers).
///
/// UI/DB code notifies here without knowing about widgets or Siri.
/// [NativeProjectionService] is the subscriber that refreshes App Group
/// projections.
class StorageChangeBus {
  static final List<void Function()> _listeners = <void Function()>[];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void notifyChanged() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  /// Test-only: clear listeners between cases.
  static void debugReset() {
    _listeners.clear();
  }
}
