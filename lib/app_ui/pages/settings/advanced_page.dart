import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/widgets/page.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/ui.dart' show BaseNavigator, BaseScaffold;
import 'package:fl_clash/views/config/custom_resources.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/rules.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/views/views.dart'
    show DeveloperView, DisclaimerView, ResourcesView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// Everything a typical user never changes, grouped by what it touches.
class SsAdvancedPage extends ConsumerWidget {
  const SsAdvancedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final developerMode = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    void push(Widget page) => BaseNavigator.push(context, page);
    return SsPage(
      title: l.ssAdvancedLead,
      accent: l.ssAdvancedAccent,
      subtitle: l.ssAdvancedDesc,
      children: [
        SsGroup(
          title: l.network,
          children: [
            SsRow(
              icon: LucideIcons.shieldHalf,
              iconColor: palette.mint,
              title: l.ssNetworkVpn,
              subtitle: l.ssNetworkVpnDesc,
              chevron: true,
              onTap: () => push(
                BaseScaffold(title: l.network, body: const NetworkListView()),
              ),
            ),
            SsRow(
              icon: LucideIcons.globe,
              iconColor: palette.sky,
              title: 'DNS',
              subtitle: l.ssDnsDesc,
              chevron: true,
              onTap: () => push(const DnsView()),
            ),
            SsRow(
              icon: LucideIcons.slidersHorizontal,
              iconColor: palette.lavender,
              title: l.ssCoreParams,
              subtitle: l.ssCoreParamsDesc,
              chevron: true,
              onTap: () => push(const GeneralView()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SsGroup(
          title: l.ssRouting,
          children: [
            SsRow(
              icon: LucideIcons.listChecks,
              iconColor: palette.lemon,
              title: l.addedRules,
              subtitle: l.ssRulesDesc,
              chevron: true,
              onTap: () => push(const AddedRulesView()),
            ),
            SsRow(
              icon: LucideIcons.fileCode,
              iconColor: palette.peach,
              title: l.script,
              subtitle: l.ssScriptsDesc,
              chevron: true,
              onTap: () => push(const ScriptsView()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SsGroup(
          title: l.resources,
          children: [
            SsRow(
              icon: LucideIcons.database,
              iconColor: palette.sky,
              title: l.resources,
              subtitle: l.ssResourcesDesc,
              chevron: true,
              onTap: () => push(const ResourcesView()),
            ),
            SsRow(
              icon: LucideIcons.layers,
              iconColor: palette.lavender,
              title: l.customProfileResources,
              subtitle: l.customProfileResourcesDesc,
              chevron: true,
              onTap: () => push(const CustomResourcesView()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SsGroup(
          title: l.other,
          children: [
            SsRow(
              icon: LucideIcons.scale,
              iconColor: palette.textMuted,
              title: l.disclaimer,
              chevron: true,
              onTap: () => push(const DisclaimerView()),
            ),
            if (developerMode)
              SsRow(
                icon: LucideIcons.cpu,
                iconColor: palette.rose,
                title: l.developerMode,
                chevron: true,
                onTap: () => push(const DeveloperView()),
              ),
          ],
        ),
      ],
    );
  }
}
