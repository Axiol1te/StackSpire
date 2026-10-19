import 'dart:async';

import 'package:fl_clash/app_ui/pages/home/connect_state.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_profiles.dart';

class _ConnectionState extends ConsumerStatefulWidget {
  const _ConnectionState();

  @override
  ConsumerState<_ConnectionState> createState() => _ConnectionStateState();
}

class _ConnectionStateState extends ConsumerState<_ConnectionState>
    with SsConnectStateMixin {
  @override
  Widget build(BuildContext context) => Text(watchConnectState().name);
}

void main() {
  late ProviderContainer container;
  late StreamController<ServiceRunState?> states;

  Future<void> mount(WidgetTester tester, {bool running = true}) async {
    states = StreamController<ServiceRunState?>();
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(
          () => TestProfiles([
            const Profile(id: 1, autoUpdateDuration: Duration(hours: 12)),
          ]),
        ),
        isStartProvider.overrideWith(
          (ref) => ref.watch(runTimeProvider) != null,
        ),
        suspendProvider.overrideWith((ref) => false),
        coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
        ssServiceRunStateProvider.overrideWith((ref) => states.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await states.close();
    });
    container.read(runTimeProvider.notifier).value = running ? 1 : null;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: _ConnectionState(),
        ),
      ),
    );
  }

  Future<void> report(WidgetTester tester, ServiceRunState state) async {
    states.add(state);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('native readiness connects without an IP probe or minimum hold', (
    tester,
  ) async {
    await mount(tester);
    await report(tester, ServiceRunState.starting);
    expect(find.text('connecting'), findsOneWidget);
    await report(tester, ServiceRunState.started);
    expect(find.text('connected'), findsOneWidget);
  });

  testWidgets('a slow native start never becomes connected on a timer', (
    tester,
  ) async {
    await mount(tester);
    await report(tester, ServiceRunState.starting);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('connecting'), findsOneWidget);
  });

  testWidgets('stop remains visible until native teardown completes', (
    tester,
  ) async {
    await mount(tester);
    await report(tester, ServiceRunState.started);
    container.read(runTimeProvider.notifier).value = null;
    await tester.pump();
    expect(find.text('disconnecting'), findsOneWidget);
    await report(tester, ServiceRunState.stopping);
    expect(find.text('disconnecting'), findsOneWidget);
    await report(tester, ServiceRunState.stopped);
    expect(find.text('off'), findsOneWidget);
  });

  testWidgets('a rejected start returns to off immediately', (tester) async {
    await mount(tester);
    await report(tester, ServiceRunState.starting);
    container.read(runTimeProvider.notifier).value = null;
    await report(tester, ServiceRunState.stopped);
    expect(find.text('off'), findsOneWidget);
  });

  testWidgets('reattaching to a running service needs no presentation hold', (
    tester,
  ) async {
    await mount(tester);
    await report(tester, ServiceRunState.started);
    expect(find.text('connected'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
