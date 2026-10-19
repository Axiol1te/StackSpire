import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/spinner.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// Pastel tier of a measured delay: fast mint, fair lemon, slow peach, a
/// failed or timed-out probe rose.
Color ssDelayColor(SsPalette palette, int? delay) {
  if (delay == null) {
    return palette.textMuted;
  }
  if (delay <= 0) {
    return palette.rose;
  }
  if (delay < 300) {
    return palette.mint;
  }
  if (delay < 800) {
    return palette.lemon;
  }
  return palette.peach;
}

/// A node's latency as a tinted pill; tapping it measures again.
class SsDelayBadge extends ConsumerWidget {
  const SsDelayBadge({
    super.key,
    required this.proxyName,
    this.testUrl,
    this.onTest,
  });

  final String proxyName;
  final String? testUrl;
  final VoidCallback? onTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.ss;
    final l = context.appLocalizations;
    final delay = ref.watch(
      delayProvider(proxyName: proxyName, testUrl: testUrl),
    );
    final phase = ref.watch(
      delayTestPhaseProvider(proxyName: proxyName, testUrl: testUrl),
    );
    final color = ssDelayColor(palette, delay);
    final Widget content = switch (phase) {
      DelayTestPhase.running => SsSpinner(
        key: const ValueKey('running'),
        size: 12,
        color: palette.accent,
      ),
      DelayTestPhase.queued => Icon(
        LucideIcons.clock,
        key: const ValueKey('queued'),
        size: 12,
        color: palette.textFaint,
      ),
      null when delay == null => Icon(
        LucideIcons.zap,
        key: const ValueKey('idle'),
        size: 12,
        color: palette.textMuted,
      ),
      null => Text(
        delay! > 0 ? '$delay ms' : delayFailureText(delay, l),
        key: ValueKey(delay),
        maxLines: 1,
        style: SsType.monoSmall.color(color),
      ),
    };
    return Tooltip(
      message: l.delayTest,
      child: Semantics(
        button: true,
        label: delay != null && delay > 0
            ? '${l.delayTest}: $delay ms'
            : l.delayTest,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTest ?? () => _test(ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
            child: Center(
              child: AnimatedContainer(
                duration: SsMotion.of(context, SsMotion.medium),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: ShapeDecoration(
                  color: delay == null || phase != null
                      ? palette.raisedHigh
                      : palette.tint(color, palette.isDark ? 0.14 : 0.13),
                  shape: AppShape.full.copyWith(
                    side: BorderSide(
                      color: delay == null || phase != null
                          ? palette.border
                          : color.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: SsMotion.of(context, SsMotion.fast),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _test(WidgetRef ref) {
    final group = ref.read(groupsProvider).getGroup(proxyName);
    final proxy = group == null
        ? ref
              .read(groupsProvider)
              .expand((group) => group.all)
              .where((proxy) => proxy.name == proxyName)
              .firstOrNull
        : null;
    final actions = ref.read(proxiesActionProvider.notifier);
    if (group != null) {
      actions.delayTest(group.all, testUrl ?? group.testUrl);
    } else if (proxy != null) {
      actions.proxyDelayTest(proxy, testUrl);
    }
  }
}
