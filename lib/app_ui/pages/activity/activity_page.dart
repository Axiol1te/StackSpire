import 'package:fl_clash/app_ui/pages/activity/ip_card.dart';
import 'package:fl_clash/app_ui/shell/shell.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/layout.dart';
import 'package:fl_clash/app_ui/widgets/reveal.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/ui.dart' show BaseNavigator;
import 'package:fl_clash/views/views.dart'
    show ConnectionsView, DnsQueriesView, LogsView, RequestsView;
import 'package:fl_clash/views/dashboard/widgets/widgets.dart'
    show ConnectionStatsCard, IntranetIpCard, MemoryInfo, ServiceStatusCard;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SsActivityPage extends ConsumerWidget {
  const SsActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final top = MediaQuery.paddingOf(context).top;
    final side = ssSidePadding(context);
    final bottom = SsShellInsets.bottomOf(context);
    final openLogs = ref.watch(
      appSettingProvider.select((state) => state.openLogs),
    );
    final requestCount = ref.watch(requestCountProvider);
    final dnsCount = ref.watch(dnsQueryCountProvider);
    var i = 0;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, top + 16, side, bottom),
          sliver: SliverList.list(
            children: [
              SsReveal(
                index: i++,
                child: SsHeadline([
                  SsRun(l.ssActivityLead),
                  SsRun.accent(l.ssActivityAccent, color: palette.lavender),
                ], type: SsType.title),
              ),
              const SizedBox(height: 20),
              SsReveal(index: i++, child: const _TotalsCard()),
              const SizedBox(height: 12),
              SsReveal(index: i++, child: const SsYourIpCard()),
              const SizedBox(height: 22),
              SsReveal(
                index: i++,
                child: SsGroup(
                  title: l.ssJournals,
                  footer: openLogs ? null : l.logcatDesc,
                  children: [
                    SsRow(
                      icon: LucideIcons.cable,
                      iconColor: palette.sky,
                      title: l.connections,
                      subtitle: l.ssConnectionsDesc,
                      chevron: true,
                      onTap: () =>
                          BaseNavigator.push(context, const ConnectionsView()),
                    ),
                    SsRow(
                      icon: LucideIcons.listTree,
                      iconColor: palette.mint,
                      title: l.requests,
                      value: '$requestCount',
                      chevron: true,
                      onTap: () =>
                          BaseNavigator.push(context, const RequestsView()),
                    ),
                    SsRow(
                      icon: LucideIcons.radar,
                      iconColor: palette.lemon,
                      title: l.ssDnsQueries,
                      value: '$dnsCount',
                      chevron: true,
                      onTap: () =>
                          BaseNavigator.push(context, const DnsQueriesView()),
                    ),
                    if (openLogs)
                      SsRow(
                        icon: LucideIcons.scrollText,
                        iconColor: palette.peach,
                        title: l.logs,
                        chevron: true,
                        onTap: () =>
                            BaseNavigator.push(context, const LogsView()),
                      )
                    else
                      SsSwitchRow(
                        icon: LucideIcons.scrollText,
                        iconColor: palette.peach,
                        title: l.logcat,
                        value: false,
                        onChanged: (value) => ref
                            .read(appSettingProvider.notifier)
                            .update((state) => state.copyWith(openLogs: value)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SsReveal(index: i++, child: SsOverline(l.serviceStatus)),
              const SizedBox(height: 10),
              SsReveal(index: i++, child: const ServiceStatusCard()),
              const SizedBox(height: 22),
              SsReveal(index: i++, child: SsOverline(l.ssSystem)),
              const SizedBox(height: 10),
              SsReveal(index: i++, child: const ConnectionStatsCard()),
              const SizedBox(height: 12),
              SsReveal(index: i++, child: const IntranetIpCard()),
              const SizedBox(height: 12),
              SsReveal(index: i++, child: const MemoryInfo()),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalsCard extends ConsumerWidget {
  const _TotalsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final total = ref.watch(totalTrafficProvider);
    final latest = ref.watch(
      trafficsProvider.select((state) => state.list.safeLast(const Traffic())),
    );
    Widget cell(
      String label,
      num bytes,
      num speed,
      Color color,
      IconData icon,
    ) {
      final show = bytes.traffic;
      final speedShow = speed.traffic;
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SsType.caption.color(palette.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${show.value} ${show.unit}',
                style: SsType.monoLarge.style.copyWith(
                  fontSize: 24,
                  color: palette.text,
                ),
              ),
            ),
            Text(
              '${speedShow.value} ${speedShow.unit}/s',
              style: SsType.monoSmall.color(color),
            ),
          ],
        ),
      );
    }

    return SsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SsOverline(l.trafficUsage),
          const SizedBox(height: 12),
          Row(
            children: [
              cell(
                l.download,
                total.down,
                latest.down,
                palette.accent,
                LucideIcons.arrowDown,
              ),
              const SizedBox(width: 16),
              cell(
                l.upload,
                total.up,
                latest.up,
                palette.lavender,
                LucideIcons.arrowUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
