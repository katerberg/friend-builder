import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/services/native_projection_service.dart';
import 'package:friend_builder/storage_change_bus.dart';

void main() {
  tearDown(() {
    NativeProjectionService.debugReset();
    StorageChangeBus.debugReset();
  });

  test('StorageChangeBus notifies all listeners', () {
    var count = 0;
    void listener() => count += 1;
    StorageChangeBus.addListener(listener);
    StorageChangeBus.notifyChanged();
    StorageChangeBus.notifyChanged();
    expect(count, 2);
    StorageChangeBus.removeListener(listener);
    StorageChangeBus.notifyChanged();
    expect(count, 2);
  });

  test('NativeProjectionService debounces StorageChangeBus bursts', () {
    fakeAsync((async) {
      var refreshCount = 0;
      NativeProjectionService.debugRefreshOverride = () async {
        refreshCount += 1;
        return true;
      };
      NativeProjectionService.start();

      StorageChangeBus.notifyChanged();
      StorageChangeBus.notifyChanged();
      StorageChangeBus.notifyChanged();
      expect(refreshCount, 0);
      expect(async.pendingTimers.length, 1);

      async.elapse(NativeProjectionService.debounceDuration);
      async.flushMicrotasks();
      expect(refreshCount, 1);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('refreshNow cancels debounce and runs immediately', () {
    fakeAsync((async) {
      var refreshCount = 0;
      NativeProjectionService.debugRefreshOverride = () async {
        refreshCount += 1;
        return true;
      };
      NativeProjectionService.start();

      StorageChangeBus.notifyChanged();
      expect(async.pendingTimers.length, 1);

      NativeProjectionService.refreshNow();
      async.flushMicrotasks();
      expect(refreshCount, 1);
      expect(async.pendingTimers, isEmpty);

      async.elapse(NativeProjectionService.debounceDuration);
      async.flushMicrotasks();
      expect(refreshCount, 1);
    });
  });
}
