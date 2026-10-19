import 'dart:async';

import 'package:fl_clash/app_ui/pages/home/connect_button.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ssServiceRunStateProvider = StreamProvider.autoDispose<ServiceRunState?>((
  ref,
) {
  final platformService = service;
  if (platformService == null) return Stream.value(null);
  final states = StreamController<ServiceRunState?>();
  final listener = _RunStateListener(states.add);
  platformService.addListener(listener);
  states.add(platformService.runState);
  ref.onDispose(() {
    platformService.removeListener(listener);
    unawaited(states.close());
  });
  return states.stream;
});

class _RunStateListener with ServiceListener {
  final void Function(ServiceRunState) changed;

  _RunStateListener(this.changed);

  @override
  void onServiceStateChanged(ServiceRunState state) => changed(state);
}

mixin SsConnectStateMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  SsConnectState watchConnectState() {
    final hasProfile = ref.watch(
      profilesProvider.select((profiles) => profiles.isNotEmpty),
    );
    final isStart = ref.watch(isStartProvider);
    final suspended = ref.watch(suspendProvider);
    final coreReady = ref.watch(coreStatusProvider) == CoreStatus.connected;
    final nativeState =
        ref.watch(ssServiceRunStateProvider).value ?? service?.runState;
    if (nativeState == ServiceRunState.stopping ||
        (!isStart && nativeState == ServiceRunState.started)) {
      return SsConnectState.disconnecting;
    }
    if (!isStart && nativeState == ServiceRunState.starting) {
      return SsConnectState.connecting;
    }
    if (!hasProfile && !isStart) return SsConnectState.unavailable;
    if (!isStart) return SsConnectState.off;
    if (suspended) return SsConnectState.suspended;
    if (!coreReady ||
        (nativeState != null && nativeState != ServiceRunState.started)) {
      return SsConnectState.connecting;
    }
    return SsConnectState.connected;
  }
}
