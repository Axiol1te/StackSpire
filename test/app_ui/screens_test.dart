import 'package:fl_clash/app_ui/pages/activity/ip_card.dart';
import 'package:fl_clash/app_ui/pages/home/home_cards.dart';
import 'package:fl_clash/app_ui/pages/settings/routing_mode.dart';
import 'package:fl_clash/app_ui/shell/nav_bar.dart';
// Renders every StackSpire screen at phone sizes, both themes and a large text
// scale. A layout overflow fails the test; `--update-goldens` writes the PNGs
// to test/app_ui/screens/ for review.
import 'dart:async';
import 'dart:io';

import 'package:fl_clash/app_ui/app_ui.dart';
import 'package:fl_clash/app_ui/flows/add_profile.dart';
import 'package:fl_clash/app_ui/pages/home/connect_state.dart';
import 'package:fl_clash/app_ui/pages/servers/servers_menu.dart';
import 'package:fl_clash/app_ui/pages/servers/profile_card.dart';
import 'package:fl_clash/app_ui/pages/servers/group_section.dart';
import 'package:fl_clash/app_ui/pages/servers/servers_page.dart';
import 'package:fl_clash/app_ui/pages/settings/about_page.dart';
import 'package:fl_clash/app_ui/pages/settings/advanced_page.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/service_probe.dart' show routedOutbound;
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/desktop/model.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/ip_quality.dart';
import 'package:fl_clash/providers/outbound_ip.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/providers/routed_probe.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../helpers/app_paths.dart';
import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

const _profileId = 1;

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont('Manrope', [
    for (final w in [400, 500, 600, 700]) 'assets/ss_fonts/Manrope-$w.ttf',
  ]);
  await _loadFont('Montserrat', [
    for (final w in [500, 600, 700]) ...[
      'assets/ss_fonts/Montserrat-$w.ttf',
      'assets/ss_fonts/Montserrat-${w}Italic.ttf',
    ],
  ]);
  await _loadFont('JetBrainsMono', [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/ss_fonts/JetBrainsMono-500.ttf',
    'assets/ss_fonts/JetBrainsMono-600.ttf',
  ]);
  await _loadFont('Twemoji', ['assets/fonts/Twemoji.Mozilla.ttf']);
  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['LOCALAPPDATA']}/Pub/Cache';
  await _loadFont('packages/lucide_icons_flutter/Lucide', [
    '$pubCache/hosted/pub.dev/lucide_icons_flutter-3.1.21/assets/build_font/LucideVariable-w400.ttf',
  ]);
}

final _profile = Profile(
  id: _profileId,
  type: ProfileType.url,
  label: 'Stack Cloud · Premium',
  url: 'https://example.com/sub',
  autoUpdateDuration: const Duration(hours: 12),
  lastUpdateDate: DateTime(2026, 10, 18, 9),
  currentGroupName: 'Proxy',
  selectedMap: const {'Proxy': '🇩🇪 Frankfurt 02'},
  unfoldSet: const {'Proxy'},
  subscriptionInfo: SubscriptionInfo(
    upload: 3 * 1024 * 1024 * 1024,
    download: 41 * 1024 * 1024 * 1024,
    total: 200 * 1024 * 1024 * 1024,
    expire:
        DateTime.now().add(const Duration(days: 23)).millisecondsSinceEpoch ~/
        1000,
  ),
);

const _nodes = [
  Proxy(name: '🇩🇪 Frankfurt 02', type: 'VLESS'),
  Proxy(name: '🇳🇱 Amsterdam 01', type: 'Trojan'),
  Proxy(
    name: '🇫🇮 Helsinki — very long node name for overflow checks',
    type: 'Hysteria2',
  ),
  Proxy(name: '🇯🇵 Tokyo 03', type: 'VMess'),
  Proxy(name: '🇺🇸 New York 11', type: 'Shadowsocks'),
  Proxy(name: 'Без флага', type: 'WireGuard'),
];

final _groups = [
  const Group(
    type: GroupType.Selector,
    name: 'Proxy',
    all: _nodes,
    hidden: false,
  ),
  const Group(
    type: GroupType.URLTest,
    name: 'Auto · fastest',
    all: _nodes,
    hidden: false,
  ),
  const Group(
    type: GroupType.Selector,
    name: 'Streaming',
    hidden: false,
    all: [
      Proxy(name: 'Proxy', type: 'Selector'),
      ..._nodes,
    ],
  ),
];

final _delays = <String, Map<String, int?>>{
  defaultTestUrl: {
    '🇩🇪 Frankfurt 02': 64,
    '🇳🇱 Amsterdam 01': 142,
    '🇫🇮 Helsinki — very long node name for overflow checks': 486,
    '🇯🇵 Tokyo 03': 1210,
    '🇺🇸 New York 11': -1,
  },
};

/// Answers nothing, as a Core that is not running would.
class _SilentCore extends CoreHandlerInterface {
  @override
  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) async => null;

  @override
  Future<CoreLifecycleResult> start() async => _unused;

  @override
  Future<CoreLifecycleResult> restart() async => _unused;

  @override
  Future<CoreLifecycleResult> stop() async => _unused;

  @override
  Future<CoreLifecycleResult> close() async => _unused;
}

const _unused = CoreLifecycleResult(
  revision: 0,
  outcome: CoreLifecycleOutcome.applied,
);

class _FakeOutboundIp extends OutboundIpProbe {
  @override
  RoutedProbeState<String, IpInfo> build() => const RoutedProbeState({
    routedOutbound: ProbeEntry(
      phase: ProbePhase.fresh,
      value: IpInfo(ip: '185.220.101.47', countryCode: 'DE'),
    ),
  });

  @override
  void watch(String target) {}

  @override
  void unwatch(String target) {}
}

List<Override> _overrides({
  required PageLabel page,
  required bool connected,
  required bool withProfile,
  List<Profile>? profiles,
}) {
  return [
    coreHandlerProvider.overrideWithValue(CoreController.scoped(_SilentCore())),
    profilesProvider.overrideWith(
      () => TestProfiles(profiles ?? (withProfile ? [_profile] : const [])),
    ),
    currentProfileIdProvider.overrideWithBuild(
      (_, _) => withProfile ? _profileId : null,
    ),
    currentPageLabelProvider.overrideWithBuild((_, _) => page),
    groupsProvider.overrideWithBuild((_, _) => withProfile ? _groups : []),
    appliedProfileIdProvider.overrideWithBuild(
      (_, _) => withProfile ? _profileId : null,
    ),
    runTimeProvider.overrideWithBuild((_, _) => connected ? 3723000 : null),
    coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
    delayDataSourceProvider.overrideWithBuild((_, _) => _delays),
    trafficsProvider.overrideWithBuild(
      (_, _) => FixedList(
        trafficSampleLength,
        list: [
          for (var i = 0; i < 30; i++)
            Traffic(
              up: (i % 7) * 18000 + 4000,
              down: ((i * 37) % 23) * 160000 + 30000,
            ),
        ],
      ),
    ),
    totalTrafficProvider.overrideWithBuild(
      (_, _) => const Traffic(up: 84 * 1024 * 1024, down: 1536 * 1024 * 1024),
    ),
    outboundIpProbeProvider.overrideWith(_FakeOutboundIp.new),
    ipQualityProvider.overrideWith(
      (ref, ip) async => IpQuality(
        ip: ip,
        source: IpQualitySource.ipApiCom,
        type: IpType.hosting,
        organization: 'Hetzner Online GmbH',
        asn: 24940,
      ),
    ),
  ];
}

typedef _Variant = ({String name, Size size, double textScale, Brightness b});

const _variants = <_Variant>[
  (name: 'small_dark', size: Size(360, 640), textScale: 1, b: Brightness.dark),
  (
    name: 'small_light',
    size: Size(360, 640),
    textScale: 1,
    b: Brightness.light,
  ),
  (
    name: 'large_text',
    size: Size(360, 640),
    textScale: 1.3,
    b: Brightness.dark,
  ),
  (name: 'big_phone', size: Size(430, 932), textScale: 1, b: Brightness.dark),
  (name: 'landscape', size: Size(800, 360), textScale: 1, b: Brightness.dark),
];

Future<void> _pumpApp(
  WidgetTester tester,
  _Variant variant,
  List<Override> overrides,
  Widget home,
) async {
  tester.view.physicalSize = variant.size * 2.5;
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = variant.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  globalState.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TestApp(
        locale: const Locale('ru'),
        theme: ssTheme(variant.b),
        darkTheme: ssTheme(variant.b),
        themeMode: variant.b == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        child: RepaintBoundary(key: const ValueKey('shot'), child: home),
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Golden PNGs depend on the host's font rasteriser, so they are written and
/// compared only when asked for; otherwise the test checks layout alone.
final _goldens = Platform.environment['SS_SCREENSHOTS'] == '1';

Future<void> _shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (!_goldens) {
    return;
  }
  await expectLater(
    find.byKey(const ValueKey('shot')),
    matchesGoldenFile('screens/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    await AppLocalizations.load(const Locale('ru'));
    await useAppPaths(Directory.systemTemp.createTempSync('ss_screens'));
    globalState.packageInfo = PackageInfo(
      appName: 'StackSpire',
      packageName: 'com.stackspire.vpn',
      version: '0.9.1',
      buildNumber: '2026101702',
    );
  });

  testWidgets('routing controls in settings still update all three modes', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _variants.first,
      _overrides(page: PageLabel.tools, connected: false, withProfile: false),
      const SsRoutingModeSettings(),
    );
    final l = currentAppLocalizations;
    for (final (label, mode) in [
      (l.global, Mode.global),
      (l.ssModeDirect, Mode.direct),
      (l.ssModeRule, Mode.rule),
    ]) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 400));
      expect(globalState.container.read(patchClashConfigProvider).mode, mode);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('home hints become a timer only after native connection', (
    tester,
  ) async {
    final states = StreamController<ServiceRunState?>();
    addTearDown(states.close);
    await _pumpApp(tester, _variants.first, [
      ..._overrides(
        page: PageLabel.dashboard,
        connected: false,
        withProfile: true,
      ),
      isStartProvider.overrideWith((ref) => ref.watch(runTimeProvider) != null),
      ssServiceRunStateProvider.overrideWith((ref) => states.stream),
    ], const SsShell());
    final l = currentAppLocalizations;
    expect(find.text(l.ssTapToConnect), findsOneWidget);
    final hintStyle = tester.widget<Text>(find.text(l.ssTapToConnect)).style;
    expect(
      tester.widget<Text>(find.text('StackSpire')).style?.fontFamily,
      hintStyle?.fontFamily,
    );
    expect(find.byKey(const ValueKey('connection-timer')), findsNothing);
    states.add(ServiceRunState.starting);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l.ssConnecting), findsOneWidget);
    expect(find.byKey(const ValueKey('connection-timer')), findsNothing);
    await tester.pump(const Duration(seconds: 9));
    expect(find.byKey(const ValueKey('connection-timer')), findsNothing);
    globalState.container.read(runTimeProvider.notifier).value = 1000;
    states.add(ServiceRunState.started);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('connection-timer')), findsOneWidget);
    expect(find.text(l.ssTapToDisconnect), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(l.ssTapToDisconnect)).style,
      hintStyle,
    );
    globalState.container.read(runTimeProvider.notifier).value = null;
    states.add(ServiceRunState.stopped);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('connection-timer')), findsNothing);
    expect(find.text(l.ssTapToConnect), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home server card opens the server tab', (tester) async {
    await _pumpApp(
      tester,
      _variants.first,
      _overrides(page: PageLabel.dashboard, connected: true, withProfile: true),
      const SsShell(),
    );
    await tester.tap(find.byType(SsServerCard));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      globalState.container.read(currentPageLabelProvider),
      PageLabel.proxies,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'only the selected subscription expands and old nodes stay hidden during switching',
    (tester) async {
      final second = _profile.copyWith(
        id: 2,
        label: 'Second subscription',
        subscriptionTitle: 'Семейная подписка',
        selectedMap: const {},
        subscriptionInfo: const SubscriptionInfo(
          upload: 0,
          download: 1024,
          total: 0,
        ),
      );
      await _pumpApp(tester, _variants.first, [
        ..._overrides(
          page: PageLabel.proxies,
          connected: true,
          withProfile: true,
          profiles: [_profile, second],
        ),
      ], const SsShell());
      expect(
        find.byKey(const ValueKey('subscription-usage-1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('subscription-usage-2')), findsNothing);
      expect(find.text(currentAppLocalizations.remote), findsNothing);
      expect(find.text('Proxy'), findsNothing);
      final secondCard = find.byType(SsProfileCard).at(1);
      await tester.ensureVisible(secondCard);
      final collapsedHeight = tester.getSize(secondCard).height;
      await tester.tap(secondCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final expandingHeight = tester.getSize(secondCard).height;
      expect(expandingHeight, greaterThan(collapsedHeight));
      await _shot(tester, 'subscriptions_expanding');
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getSize(secondCard).height, greaterThan(expandingHeight));
      await tester.drag(
        find.descendant(
          of: find.byType(SsServersPage),
          matching: find.byType(CustomScrollView),
        ),
        const Offset(0, 500),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(globalState.container.read(currentProfileIdProvider), 2);
      expect(find.byKey(const ValueKey('subscription-usage-1')), findsNothing);
      expect(
        find.byKey(const ValueKey('subscription-usage-2')),
        findsOneWidget,
      );
      expect(find.byType(SsNodeTile), findsNothing);
      expect(find.text('∞'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('subscription-usage-2')),
            )
            .value,
        0,
      );
      globalState.container.read(groupsProvider.notifier).value = const [
        Group(
          name: 'Proxy',
          hidden: false,
          type: GroupType.Selector,
          all: [Proxy(name: 'Family NL', type: 'Mieru')],
        ),
      ];
      globalState.container.read(appliedProfileIdProvider.notifier).value = 2;
      await tester.pump(const Duration(milliseconds: 600));
      await tester.scrollUntilVisible(
        find.text('Family NL'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(SsServersPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Family NL'), findsOneWidget);
      expect(find.text('Frankfurt 02'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 800));
      await _shot(tester, 'subscriptions_switched');
    },
  );

  testWidgets('missing quota is not presented as unlimited', (tester) async {
    await _pumpApp(tester, _variants.first, [
      ..._overrides(
        page: PageLabel.proxies,
        connected: true,
        withProfile: true,
        profiles: [_profile.copyWith(subscriptionInfo: null)],
      ),
    ], const SsShell());
    expect(
      find.text(currentAppLocalizations.ssTrafficUnavailable),
      findsOneWidget,
    );
    expect(find.text(currentAppLocalizations.ssTrafficUnlimited), findsNothing);
    expect(find.byKey(const ValueKey('subscription-usage-1')), findsNothing);
  });

  testWidgets(
    'subscription support links remain available without traffic metadata',
    (tester) async {
      final l = currentAppLocalizations;
      await _pumpApp(
        tester,
        _variants.first,
        _overrides(
          page: PageLabel.proxies,
          connected: true,
          withProfile: true,
          profiles: [
            _profile.copyWith(
              subscriptionInfo: null,
              supportUrl: 'https://example.com/help',
              webPageUrl: 'https://example.com/account',
            ),
          ],
        ),
        const SsShell(),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(SsProfileCard),
          matching: find.byTooltip(l.more),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(l.ssSupport), findsOneWidget);
      expect(find.text(l.ssAccountPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final variant in _variants) {
    group(variant.name, () {
      for (final (tab, page) in [
        ('home', PageLabel.dashboard),
        ('servers', PageLabel.proxies),
        ('activity', PageLabel.connections),
        ('settings', PageLabel.tools),
      ]) {
        testWidgets('$tab connected', (tester) async {
          await _pumpApp(
            tester,
            variant,
            _overrides(page: page, connected: true, withProfile: true),
            const SsShell(),
          );
          if (tab == 'activity') {
            expect(find.byType(SsYourIpCard), findsOneWidget);
            expect(find.text('185.220.101.47'), findsOneWidget);
          }
          if (tab == 'home') {
            final l = currentAppLocalizations;
            expect(find.byTooltip(l.settings), findsNothing);
            expect(find.text('StackSpire'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('connection-timer')),
              findsOneWidget,
            );
            expect(find.text(l.ssHeroOnLead), findsNothing);
            expect(find.text(l.outboundIp), findsNothing);
            expect(find.text(l.ssSubscription), findsNothing);
            expect(find.byTooltip(l.delayTest), findsNothing);
            expect(find.text('Proxy'), findsNothing);
            expect(find.byType(SsRoutingModeSettings), findsNothing);
            if (variant.textScale == 1 && variant.size.height >= 640) {
              final scrollable = tester.state<ScrollableState>(
                find
                    .descendant(
                      of: find.byKey(const ValueKey('home-scroll')),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              expect(scrollable.position.maxScrollExtent, lessThanOrEqualTo(1));
              expect(
                tester.getBottomRight(find.byType(SsServerCard)).dy,
                lessThanOrEqualTo(tester.getTopLeft(find.byType(SsNavBar)).dy),
              );
            }
          }
          await _shot(tester, '${variant.name}_$tab');
        });
      }

      testWidgets('home empty', (tester) async {
        await _pumpApp(
          tester,
          variant,
          _overrides(
            page: PageLabel.dashboard,
            connected: false,
            withProfile: false,
          ),
          const SsShell(),
        );
        await _shot(tester, '${variant.name}_home_empty');
      });

      testWidgets('home off', (tester) async {
        await _pumpApp(
          tester,
          variant,
          _overrides(
            page: PageLabel.dashboard,
            connected: false,
            withProfile: true,
          ),
          const SsShell(),
        );
        expect(
          find.text(currentAppLocalizations.ssTapToConnect),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('connection-timer')), findsNothing);
        await _shot(tester, '${variant.name}_home_off');
      });

      testWidgets('home stopping', (tester) async {
        await _pumpApp(tester, variant, [
          ..._overrides(
            page: PageLabel.dashboard,
            connected: false,
            withProfile: true,
          ),
          ssServiceRunStateProvider.overrideWith(
            (ref) => Stream.value(ServiceRunState.stopping),
          ),
        ], const SsShell());
        expect(find.text('Остановка VPN…'), findsOneWidget);
        expect(find.byKey(const ValueKey('connection-timer')), findsNothing);
        expect(tester.takeException(), isNull);
      });

      for (final (name, page) in [
        ('advanced', const SsAdvancedPage()),
        ('about', const SsAboutPage()),
        ('providers', const SsProvidersPage()),
      ]) {
        testWidgets(name, (tester) async {
          await _pumpApp(
            tester,
            variant,
            _overrides(
              page: PageLabel.tools,
              connected: true,
              withProfile: true,
            ),
            page,
          );
          await _shot(tester, '${variant.name}_$name');
        });
      }

      testWidgets('add sheet', (tester) async {
        await _pumpApp(
          tester,
          variant,
          _overrides(
            page: PageLabel.dashboard,
            connected: false,
            withProfile: false,
          ),
          const SsShell(),
        );
        final context = tester.element(find.byType(SsShell));
        unawaited(showSsAddProfileSheet(context));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        if (_goldens) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('screens/${variant.name}_add_sheet.png'),
          );
        }
      });
    });
  }
}
