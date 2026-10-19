import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/widgets/page.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/segmented.dart';
import 'package:fl_clash/app_ui/widgets/sheet.dart';
import 'package:fl_clash/app_ui/widgets/states.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/ui.dart' show showSheet;
import 'package:fl_clash/views/profiles/profiles.dart'
    show ReorderableProfilesSheet;
import 'package:fl_clash/views/proxies/providers.dart'
    show ExternalProvidersSliver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showServersMenu(BuildContext context) {
  return showSsSheet<void>(
    context: context,
    builder: (sheetContext) => const _ServersMenu(),
  );
}

class _ServersMenu extends ConsumerWidget {
  const _ServersMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final style = ref.watch(proxiesStyleSettingProvider);
    final profiles = ref.watch(profilesProvider);
    void update(ProxiesStyleProps Function(ProxiesStyleProps) change) =>
        ref.read(proxiesStyleSettingProvider.notifier).update(change);
    return SsSheetFrame(
      title: l.ssViewAndSort,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SsSegmented<ProxiesSortType>(
              value: style.sortType,
              onChanged: (value) =>
                  update((state) => state.copyWith(sortType: value)),
              segments: [
                SsSegment(
                  value: ProxiesSortType.none,
                  label: l.defaultText,
                  icon: LucideIcons.listOrdered,
                ),
                SsSegment(
                  value: ProxiesSortType.delay,
                  label: l.delay,
                  icon: LucideIcons.gauge,
                ),
                SsSegment(
                  value: ProxiesSortType.name,
                  label: l.name,
                  icon: LucideIcons.arrowDownAZ,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SsGroup(
              footer: l.hideTimeoutProxiesDesc,
              children: [
                SsSwitchRow(
                  icon: LucideIcons.eyeOff,
                  iconColor: palette.peach,
                  title: l.hideTimeoutProxies,
                  value: style.hideTimeoutProxies,
                  onChanged: (value) => update(
                    (state) => state.copyWith(hideTimeoutProxies: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SsGroup(
              children: [
                SsRow(
                  icon: LucideIcons.boxes,
                  iconColor: palette.lavender,
                  title: l.providers,
                  subtitle: l.ssProvidersDesc,
                  chevron: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    pushSsPage<void>(context, const SsProvidersPage());
                  },
                ),
                if (profiles.length > 1)
                  SsRow(
                    icon: LucideIcons.arrowUpDown,
                    iconColor: palette.sky,
                    title: l.profilesSort,
                    chevron: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      showSheet<void>(
                        context: context,
                        builder: (_) =>
                            ReorderableProfilesSheet(profiles: profiles),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SsProvidersPage extends ConsumerWidget {
  const SsProvidersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final providers = ref.watch(providersProvider);
    return SsPage(
      title: l.providers,
      subtitle: l.ssProvidersDesc,
      slivers: [
        if (providers.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: ExternalProvidersSliver(providers: providers),
          ),
      ],
      children: [
        if (providers.isEmpty)
          SsStateView(icon: LucideIcons.boxes, title: l.nullTip(l.providers)),
      ],
    );
  }
}
