import 'dart:async';

import '../data/mock_blockable_apps.dart';
import '../models/blockable_app.dart';
import '../models/blocking_mode.dart';
import '../services/android_focus_notification.dart';
import '../services/app_block_service.dart';
import '../services/mode_app_selection_service.dart';
import 'focus_timer_controller.dart';

/// Android has a single blocking list, so sessions must share an owner.
class BlockingSessionCoordinator {
  BlockingModeSession? _owner;

  void reserve(BlockingModeSession session) {
    if (_owner != null && _owner != session) {
      throw StateError(
        'Stop your ${_owner!.mode.title.toLowerCase()} session before starting ${session.mode.title.toLowerCase()}.',
      );
    }

    _owner = session;
  }

  void release(BlockingModeSession session) {
    if (_owner == session) {
      _owner = null;
    }
  }
}

/// App-owned session: navigation does not discard its selection or cleanup.
class BlockingModeSession extends FocusTimerController {
  BlockingModeSession({
    required this.mode,
    required this.coordinator,
    ModeAppSelectionService? selections,
    super.now,
  }) : _selections = selections ?? ModeAppSelectionService(),
       super(
         notification: AndroidFocusNotification(
           title: '${mode.title} Mode',
         ),
       ) {
    addListener(_completed);
  }

  final BlockingMode mode;
  final BlockingSessionCoordinator coordinator;
  final ModeAppSelectionService _selections;

  Set<String> _selectedAppIds = {};

  bool selectionLoaded = false;
  bool busy = false;

  String? cleanupError;

  bool _blockingOwned = false;
  bool _disposed = false;

  Future<void>? _cleanup;

  final Map<String, DateTime> _temporaryUnblocks = {};
  final Map<String, Timer> _relockTimers = {};

  Set<String> get selectedAppIds =>
      Set.unmodifiable(_selectedAppIds);

  Map<String, DateTime> get temporaryUnblocks =>
      Map.unmodifiable(_temporaryUnblocks);

  List<BlockableApp> get selectedApps =>
      MockBlockableApps.all
          .where(
            (app) => _selectedAppIds.contains(app.id),
          )
          .toList();

  @override
  String get statusMessage =>
      mode == BlockingMode.focus
          ? super.statusMessage
          : switch (status) {
              FocusTimerStatus.ready =>
                'Make room for a good book.',

              FocusTimerStatus.running =>
                'Stay with the page in front of you.',

              FocusTimerStatus.paused =>
                'Your reading session is paused.',

              FocusTimerStatus.completed =>
                'You made time to read.',
            };

  Future<void> loadSelection() async {
    if (selectionLoaded) {
      return;
    }

    _selectedAppIds =
        await _selections.load(mode);

    selectionLoaded = true;
  }

  Future<void> saveSelection(
    Set<String> ids,
  ) async {
    if (
      status != FocusTimerStatus.ready
    ) {
      throw StateError(
        'Stop the session before changing its apps.',
      );
    }

    final snapshot =
        Set<String>.from(ids);

    await _selections.save(
      mode,
      snapshot,
    );

    _selectedAppIds = snapshot;

    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _action(
    Future<void> Function() action,
  ) async {
    if (busy) {
      return;
    }

    busy = true;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      await action();
    } finally {
      busy = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------
  // START SESSION
  // ---------------------------------------------------------

  Future<void> startBlockingSession() =>
      _action(() async {
        await loadSelection();

        if (_selectedAppIds.isEmpty) {
          throw StateError(
            'Select at least one app to pause.',
          );
        }

        if (
          status != FocusTimerStatus.ready
        ) {
          return;
        }

        coordinator.reserve(this);

        _blockingOwned = true;

        try {
          // Existing teammate functionality:
          // Send the selected app package names to Android.
          await AppBlockService.setBlockedApps(
            selectedApps
                .map(
                  (app) => app.packageName,
                )
                .toList(),
          );

          // Existing teammate functionality:
          // Start blocking the selected apps.
          await AppBlockService.startBlocking();

          // NEW:
          // Notification suppression is only enabled
          // when the current mode is Reading Mode.
          if (
            mode == BlockingMode.reading
          ) {
            await AppBlockService
                .setNotificationSuppressionEnabled(
              true,
            );
          }

          // Existing timer.
          startSession();
        } catch (_) {
          await stopBlocking();
          rethrow;
        }
      });

  // ---------------------------------------------------------
  // PAUSE SESSION
  // ---------------------------------------------------------

  Future<void> pauseBlockingSession() =>
      _action(() async {
        if (
          status != FocusTimerStatus.running
        ) {
          return;
        }

        // NEW:
        // Stop notification suppression while
        // Reading Mode is paused.
        if (
          mode == BlockingMode.reading
        ) {
          await AppBlockService
              .setNotificationSuppressionEnabled(
            false,
          );
        }

        // Existing teammate functionality.
        await AppBlockService.stopBlocking();

        pauseSession();
      });

  // ---------------------------------------------------------
  // RESUME SESSION
  // ---------------------------------------------------------

  Future<void> resumeBlockingSession() =>
      _action(() async {
        if (
          status != FocusTimerStatus.paused
        ) {
          return;
        }

        coordinator.reserve(this);

        // Restore the selected apps.
        await AppBlockService.setBlockedApps(
          selectedApps
              .map(
                (app) => app.packageName,
              )
              .toList(),
        );

        // Start app blocking again.
        await AppBlockService.startBlocking();

        // NEW:
        // Turn notification suppression back on
        // when Reading Mode resumes.
        if (
          mode == BlockingMode.reading
        ) {
          await AppBlockService
              .setNotificationSuppressionEnabled(
            true,
          );
        }

        resumeSession();
      });

  // ---------------------------------------------------------
  // STOP SESSION
  // ---------------------------------------------------------

  Future<void> stopBlockingSession() =>
      _action(() async {
        await stopBlocking();

        cancelSession();
      });

  // ---------------------------------------------------------
  // AUTOMATIC TIMER COMPLETION
  // ---------------------------------------------------------

  void _completed() {
    if (
      status == FocusTimerStatus.completed &&
      _blockingOwned &&
      _cleanup == null &&
      cleanupError == null
    ) {
      unawaited(
        stopBlocking().catchError(
          (Object error) {
            cleanupError =
                'Could not release blocked apps. Please try stopping again.';

            if (!_disposed) {
              notifyListeners();
            }
          },
        ),
      );
    }
  }

  Future<void> stopBlocking() {
    if (_cleanup != null) {
      return _cleanup!;
    }

    return _cleanup =
        _stopBlocking().whenComplete(() {
          _cleanup = null;
        });
  }

  // ---------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------

  Future<void> _stopBlocking() async {
    if (!_blockingOwned) {
      return;
    }

    for (
      final timer in
          _relockTimers.values
    ) {
      timer.cancel();
    }

    _relockTimers.clear();

    // NEW:
    // Always restore normal notification behaviour
    // when Reading Mode ends.
    if (
      mode == BlockingMode.reading
    ) {
      await AppBlockService
          .setNotificationSuppressionEnabled(
        false,
      );
    }

    // Existing teammate functionality:
    // release app blocking.
    await AppBlockService.stopBlocking();

    for (
      final package in
          _temporaryUnblocks.keys.toList()
    ) {
      await AppBlockService
          .clearTemporaryUnblock(
        package,
      );
    }

    _temporaryUnblocks.clear();

    cleanupError = null;

    _blockingOwned = false;

    coordinator.release(this);
  }

  // ---------------------------------------------------------
  // TEMPORARY APP UNBLOCKING
  // ---------------------------------------------------------

  void updateTemporaryUnblocks(
    Map<String, DateTime> unblocks,
  ) {
    for (
      final timer in
          _relockTimers.values
    ) {
      timer.cancel();
    }

    _relockTimers.clear();

    _temporaryUnblocks
      ..clear()
      ..addAll(unblocks);

    for (
      final entry in
          unblocks.entries
    ) {
      _relockTimers[
              entry.key]
          ?.cancel();

      final delay =
          entry.value.difference(
        DateTime.now(),
      );

      _relockTimers[entry.key] =
          Timer(
        delay.isNegative
            ? Duration.zero
            : delay,
        () async {
          try {
            await AppBlockService
                .clearTemporaryUnblock(
              entry.key,
            );

            _temporaryUnblocks.remove(
              entry.key,
            );

            _relockTimers.remove(
              entry.key,
            );

            if (!_disposed) {
              notifyListeners();
            }
          } catch (_) {
            /*
             * Native unblock deadlines still
             * expire independently.
             */
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;

    removeListener(_completed);

    for (
      final timer in
          _relockTimers.values
    ) {
      timer.cancel();
    }

    unawaited(
      stopBlocking().catchError(
        (Object _) {},
      ),
    );

    super.dispose();
  }
}