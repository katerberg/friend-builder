import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:friend_builder/services/due_friend_snapshot_service.dart';
import 'package:friend_builder/storage_change_bus.dart';

/// Single subscriber that projects domain data into App Group / widgets / Siri.
///
/// Listens to [StorageChangeBus], debounces bursts of mutations, and refreshes
/// the due-friend snapshot plus friend catalog together.
class NativeProjectionService {
  static const Duration debounceDuration = Duration(milliseconds: 400);

  static Timer? _debounceTimer;
  static bool _started = false;
  static Future<bool>? _inFlightRefresh;
  static bool _dirty = false;

  /// Test-only hook that replaces the real App Group refresh.
  static Future<bool> Function()? debugRefreshOverride;

  static void start() {
    if (_started) {
      return;
    }
    StorageChangeBus.addListener(scheduleRefresh);
    _started = true;
  }

  /// Coalesce rapid Storage writes into one projection refresh.
  static void scheduleRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      refreshNow();
    });
  }

  /// Cancel any pending debounce and refresh immediately (e.g. post-drain).
  static Future<bool> refreshNow() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    return _runRefresh();
  }

  /// If a refresh is already running, mark dirty and join it so a follow-up
  /// pass runs after the in-flight work finishes (includes newer mutations).
  static Future<bool> _runRefresh() {
    final existingRefresh = _inFlightRefresh;
    if (existingRefresh != null) {
      _dirty = true;
      return existingRefresh;
    }

    late final Future<bool> refreshFuture;
    refreshFuture = () async {
      var success = true;
      do {
        _dirty = false;
        success = await _performRefresh();
      } while (_dirty);
      if (identical(_inFlightRefresh, refreshFuture)) {
        _inFlightRefresh = null;
      }
      if (_dirty) {
        return _runRefresh();
      }
      return success;
    }();

    _inFlightRefresh = refreshFuture;
    return refreshFuture;
  }

  static Future<bool> _performRefresh() {
    final override = debugRefreshOverride;
    if (override != null) {
      return override();
    }
    return DueFriendSnapshotService.refresh();
  }

  /// Live ranking payload for warm MethodChannel callers.
  static Future<Map<String, dynamic>> refreshAndReturnPayload() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    try {
      return await DueFriendSnapshotService.refreshAndReturnPayload();
    } catch (error) {
      if (kDebugMode) {
        print('NativeProjectionService refreshAndReturnPayload failed: $error');
      }
      rethrow;
    }
  }

  /// Test-only: tear down timers and bus subscription.
  static void debugReset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _inFlightRefresh = null;
    _dirty = false;
    debugRefreshOverride = null;
    if (_started) {
      StorageChangeBus.removeListener(scheduleRefresh);
      _started = false;
    }
  }
}
