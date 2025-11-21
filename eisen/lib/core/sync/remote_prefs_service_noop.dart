import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/sync/remote_prefs_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class RemotePrefsServiceNoop implements RemotePrefsService {
  const RemotePrefsServiceNoop();

  @override
  Future<UiPrefsData?> fetchRemotePrefs() async => null;

  @override
  Future<void> pushRemotePrefs(UiPrefsData prefs) async {}

  @override
  Future<UiPrefsData> resolveConflict({
    required UiPrefsData local,
    required UiPrefsData remote,
  }) async =>
      local;
}

final remotePrefsServiceProvider = Provider<RemotePrefsService>(
  (ref) => const RemotePrefsServiceNoop(),
);
