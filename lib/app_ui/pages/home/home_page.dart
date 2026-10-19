import 'package:fl_clash/app_ui/flows/add_profile.dart';
import 'package:fl_clash/app_ui/pages/home/connect_button.dart';
import 'package:fl_clash/app_ui/pages/home/connect_state.dart';
import 'package:fl_clash/app_ui/pages/home/home_cards.dart';
import 'package:fl_clash/app_ui/shell/shell.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/brand.dart' show ssAppName;
import 'package:fl_clash/app_ui/widgets/layout.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class SsHomePage extends ConsumerStatefulWidget {
  const SsHomePage({super.key});

  @override
  ConsumerState<SsHomePage> createState() => _SsHomePageState();
}

class _SsHomePageState extends ConsumerState<SsHomePage>
    with SsConnectStateMixin {
  void _handleTap(SsConnectState state) {
    if (state == SsConnectState.unavailable) {
      showSsAddProfileSheet(context);
      return;
    }
    ref.read(commonActionProvider.notifier).toggleRunning();
  }

  @override
  Widget build(BuildContext context) {
    final state = watchConnectState();
    final hasProfile = ref.watch(
      profilesProvider.select((profiles) => profiles.isNotEmpty),
    );
    final bottom = SsShellInsets.bottomOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final side = ssSidePadding(context);
    final palette = context.ss;
    final l = context.appLocalizations;
    final label = switch (state) {
      SsConnectState.off => l.ssTapToConnect,
      SsConnectState.connecting => l.ssConnecting,
      SsConnectState.disconnecting => l.stopVpn,
      SsConnectState.connected => l.ssTapToDisconnect,
      SsConnectState.suspended => l.suspended,
      SsConnectState.unavailable => l.ssAddSubscription,
    };
    final time = state == SsConnectState.connected
        ? getTimeText(ref.watch(runTimeProvider))
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final usableHeight = constraints.maxHeight - top - bottom - 24;
        final buttonSize = (usableHeight - 400).clamp(120.0, 216.0);
        return CustomScrollView(
          key: const ValueKey('home-scroll'),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(side, top + 8, side, bottom + 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          ssAppName,
                          style: SsType.monoTitle.color(palette.text),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SsConnectButton(
                            state: state,
                            size: buttonSize,
                            semanticLabel: label,
                            onTap: () => _handleTap(state),
                          ),
                          SizedBox(
                            height:
                                68 * MediaQuery.textScalerOf(context).scale(1),
                            child: AnimatedSwitcher(
                              duration: SsMotion.of(context, SsMotion.medium),
                              switchInCurve: SsMotion.enter,
                              switchOutCurve: SsMotion.exit,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.15),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: time == null
                                  ? Text(
                                      state == SsConnectState.unavailable
                                          ? l.ssAddSubscriptionHint
                                          : label,
                                      key: ValueKey(state),
                                      textAlign: TextAlign.center,
                                      style: SsType.mono.color(
                                        state == SsConnectState.connecting
                                            ? palette.accent
                                            : palette.textMuted,
                                      ),
                                    )
                                  : Column(
                                      key: ValueKey(state),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          time,
                                          key: const ValueKey(
                                            'connection-timer',
                                          ),
                                          style: SsType.monoLarge.color(
                                            palette.text,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l.ssTapToDisconnect,
                                          textAlign: TextAlign.center,
                                          style: SsType.mono.color(
                                            palette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (hasProfile)
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SsTrafficCard(),
                          SizedBox(height: 12),
                          SsServerCard(),
                        ],
                      )
                    else
                      const SsAddProfileCard(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
