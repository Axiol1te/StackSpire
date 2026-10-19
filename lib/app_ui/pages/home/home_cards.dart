import 'package:fl_clash/app_ui/flows/add_profile.dart';
import 'package:fl_clash/app_ui/shell/shell.dart';
import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/buttons.dart';
import 'package:fl_clash/app_ui/widgets/flag.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/ui.dart' show LineChart;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

void _openServers(WidgetRef ref) {
  ref.read(currentPageLabelProvider.notifier).toPage(SsTab.servers.pageLabel);
}

/// The group the home card follows: the one picked on the servers page, else
/// the first one the mode shows.
Group? watchPrimaryGroup(WidgetRef ref) {
  final groups = ref.watch(currentGroupsStateProvider).value;
  if (groups.isEmpty) {
    return null;
  }
  final current = ref.watch(
    currentProfileProvider.select((state) => state?.currentGroupName),
  );
  return groups.firstWhere(
    (group) => group.name == current,
    orElse: () => groups.first,
  );
}

class SsServerCard extends ConsumerWidget {
  const SsServerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final group = mode == Mode.direct ? null : watchPrimaryGroup(ref);
    final selected = group == null
        ? null
        : ref.watch(selectedProxyNameProvider(group.name));
    final leaf = selected == null || selected.isEmpty
        ? null
        : ref.watch(
            realSelectedProxyStateProvider(
              selected,
            ).select((state) => state.proxyName),
          );
    final shownName = switch ((mode, leaf, selected)) {
      (Mode.direct, _, _) => l.ssDirectNoProxy,
      (_, final leaf?, _) when leaf.isNotEmpty => leaf,
      (_, _, final selected?) when selected.isNotEmpty => selected,
      _ => l.ssNoServerSelected,
    };
    return SsCard(
      onTap: () => _openServers(ref),
      semanticLabel: l.ssServer,
      child: Row(
        children: [
          SsFlag(name: mode == Mode.direct ? null : shownName, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.ssServer,
                  style: SsType.caption.color(palette.textMuted),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: SsMotion.of(context, SsMotion.medium),
                  child: Text(
                    ssDisplayName(shownName),
                    key: ValueKey(shownName),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SsType.bodyStrong.color(palette.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(LucideIcons.chevronRight, size: 18, color: palette.textMuted),
        ],
      ),
    );
  }
}

class SsTrafficCard extends ConsumerWidget {
  const SsTrafficCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final traffics = ref.watch(trafficsProvider);
    final latest = traffics.list.safeLast(const Traffic());
    Widget meter(String label, IconData icon, bool download, Color color) {
      final speed = (download ? latest.down : latest.up).traffic;
      return Expanded(
        child: SsCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          semanticLabel: '$label ${speed.value} ${speed.unit}/s',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: SsType.caption.color(palette.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: speed.value,
                        style: SsType.titleSmall.color(palette.text),
                      ),
                      TextSpan(
                        text: ' ${speed.unit}/s',
                        style: SsType.monoSmall.color(palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                child: RepaintBoundary(
                  child: LineChart(
                    values: [
                      for (final traffic in traffics.list)
                        (download ? traffic.down : traffic.up).toDouble(),
                    ],
                    revision: traffics.revision,
                    capacity: traffics.maxLength,
                    minScale: 8 * 1024,
                    baselineRatio: 1,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        meter(l.download, LucideIcons.arrowDown, true, palette.accent),
        const SizedBox(width: 12),
        meter(l.upload, LucideIcons.arrowUp, false, palette.lavender),
      ],
    );
  }
}

/// Shown on the home page while there is no subscription yet.
class SsAddProfileCard extends StatelessWidget {
  const SsAddProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final palette = context.ss;
    return SsCard(
      dashed: true,
      raised: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SsHeadline([
            SsRun(l.ssEmptyTitleLead),
            SsRun.accent(l.ssEmptyTitleAccent),
          ], type: SsType.titleSmall),
          const SizedBox(height: 8),
          Text(l.ssEmptyMessage, style: SsType.body.color(palette.textMuted)),
          const SizedBox(height: 18),
          SsPill(
            label: l.ssAddSubscription,
            icon: LucideIcons.plus,
            tone: SsPillTone.accent,
            large: true,
            expand: true,
            onTap: () => showSsAddProfileSheet(context),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in SsAddMethod.quick)
                SsPill(
                  label: method.label(l),
                  icon: method.icon,
                  onTap: () => runSsAddMethod(context, method),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
