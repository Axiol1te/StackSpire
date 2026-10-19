import 'package:fl_clash/app_ui/pages/activity/activity_page.dart';
import 'package:fl_clash/app_ui/pages/home/home_page.dart';
import 'package:fl_clash/app_ui/pages/servers/servers_page.dart';
import 'package:fl_clash/app_ui/pages/settings/settings_page.dart';
import 'package:fl_clash/app_ui/shell/nav_bar.dart';
import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/widgets/backdrop.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

enum SsTab {
  home(PageLabel.dashboard),
  servers(PageLabel.proxies),
  activity(PageLabel.connections),
  settings(PageLabel.tools);

  const SsTab(this.pageLabel);

  /// The page the backend is told is showing: the proxies page is what keeps
  /// the core's group list fresh (`needUpdateGroupsProvider`).
  final PageLabel pageLabel;

  static SsTab of(PageLabel label) => switch (label) {
    PageLabel.dashboard => home,
    PageLabel.proxies || PageLabel.profiles => servers,
    PageLabel.requests ||
    PageLabel.connections ||
    PageLabel.dns ||
    PageLabel.logs => activity,
    PageLabel.tools || PageLabel.resources => settings,
  };
}

/// Space the floating navigation bar takes from the bottom of every page.
class SsShellInsets extends InheritedWidget {
  const SsShellInsets({super.key, required this.bottom, required super.child});

  final double bottom;

  static double bottomOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SsShellInsets>()?.bottom ??
      MediaQuery.paddingOf(context).bottom;

  @override
  bool updateShouldNotify(SsShellInsets oldWidget) =>
      bottom != oldWidget.bottom;
}

class SsShell extends ConsumerWidget {
  const SsShell({super.key});

  Future<void> _handleBack(WidgetRef ref, SsTab tab) async {
    if (tab != SsTab.home) {
      ref.read(currentPageLabelProvider.notifier).toPage(SsTab.home.pageLabel);
      return;
    }
    await ref.read(systemActionProvider.notifier).handleClose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = SsTab.of(ref.watch(currentPageLabelProvider));
    final l = context.appLocalizations;
    final items = [
      SsNavItem(icon: LucideIcons.house, label: l.navHome),
      SsNavItem(icon: LucideIcons.globe, label: l.navServers),
      SsNavItem(icon: LucideIcons.activity, label: l.navActivity),
      SsNavItem(icon: LucideIcons.settings2, label: l.settings),
    ];
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final navBottom = safeBottom + ssNavBarMargin;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack(ref, tab);
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: SsBackdrop(
          child: Stack(
            children: [
              Positioned.fill(
                child: SsShellInsets(
                  bottom: navBottom + ssNavBarHeight + 16,
                  child: _FadeThroughStack(
                    index: tab.index,
                    children: const [
                      SsHomePage(),
                      SsServersPage(),
                      SsActivityPage(),
                      SsSettingsPage(),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: navBottom,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      // Four labels share the bar's width; past a modest
                      // scale they would collide, and each is also announced
                      // by TalkBack in full.
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.1,
                        child: SsNavBar(
                          items: items,
                          index: tab.index,
                          onSelected: (index) => ref
                              .read(currentPageLabelProvider.notifier)
                              .toPage(SsTab.values[index].pageLabel),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps every tab alive and switches with Material's fade-through: the old
/// page fades out, then the new one fades in while scaling up from 0.94.
/// Only the outgoing and incoming tabs paint or tick during a switch.
class _FadeThroughStack extends StatefulWidget {
  const _FadeThroughStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<_FadeThroughStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  late int _current = widget.index;
  int? _previous;
  late final Set<int> _built = {widget.index};

  @override
  void didUpdateWidget(_FadeThroughStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _current) {
      return;
    }
    _previous = _current;
    _current = widget.index;
    _built.add(_current);
    if (SsMotion.reduced(context)) {
      _controller.value = 1;
      _previous = null;
      return;
    }
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _controller.isCompleted) {
        setState(() => _previous = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _fadeOut = Interval(0, 0.35, curve: SsMotion.exit);
  static const _fadeIn = Interval(0.35, 1, curve: SsMotion.enter);

  /// The same widget types wrap a page in every role, so switching roles
  /// never rebuilds the page's state.
  Widget _page(int index) {
    final active = index == _current;
    final leaving = index == _previous;
    final visible = active || leaving;
    return Offstage(
      offstage: !visible,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          var opacity = 1.0;
          var scale = 1.0;
          if (active) {
            final t = _fadeIn.transform(_controller.value);
            opacity = t;
            scale = 0.94 + 0.06 * t;
          } else if (leaving) {
            opacity = 1 - _fadeOut.transform(_controller.value);
          }
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: TickerMode(
          enabled: visible,
          child: ExcludeFocus(
            excluding: !active,
            child: IgnorePointer(
              ignoring: !active,
              child: RepaintBoundary(child: widget.children[index]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          KeyedSubtree(
            key: ValueKey(i),
            child: _built.contains(i) ? _page(i) : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
