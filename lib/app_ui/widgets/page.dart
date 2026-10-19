import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/layout.dart';
import 'package:fl_clash/app_ui/widgets/backdrop.dart';
import 'package:fl_clash/app_ui/widgets/buttons.dart';
import 'package:fl_clash/app_ui/widgets/reveal.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// An inner page: back button, a display title with an optional accent word,
/// and scrolling content on the gridded ground.
class SsPage extends StatelessWidget {
  const SsPage({
    super.key,
    required this.title,
    this.accent,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.slivers,
  });

  final String title;
  final String? accent;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  /// Lazily built content after [children], for long lists.
  final List<Widget>? slivers;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final padding = MediaQuery.paddingOf(context);
    final canPop = Navigator.of(context).canPop();
    final side = ssSidePadding(context);
    return Scaffold(
      backgroundColor: palette.ground,
      body: SsBackdrop(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                side - 8,
                padding.top + 8,
                side - 8,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    if (canPop)
                      SsIconButton(
                        icon: LucideIcons.arrowLeft,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    const Spacer(),
                    ...actions,
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 14, side, 0),
              sliver: SliverList.list(
                children: [
                  SsReveal(
                    child: Semantics(
                      header: true,
                      child: SsHeadline([
                        SsRun(title),
                        if (accent != null) SsRun.accent(accent!),
                      ], type: SsType.title),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    SsReveal(
                      index: 1,
                      child: Text(
                        subtitle!,
                        style: SsType.body.color(palette.textMuted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  for (final (i, child) in children.indexed)
                    SsReveal(index: i + 2, child: child),
                ],
              ),
            ),
            ...?slivers,
            SliverToBoxAdapter(child: SizedBox(height: padding.bottom + 28)),
          ],
        ),
      ),
    );
  }
}

/// Pushes [page] with the theme's shared-axis transition.
Future<T?> pushSsPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
}
