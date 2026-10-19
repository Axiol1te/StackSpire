import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/brand.dart';
import 'package:fl_clash/app_ui/widgets/page.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

const _links = (
  flclash: 'https://github.com/chen08209/FlClash',
  core: 'https://github.com/chen08209/Clash.Meta/tree/FlClash',
  mihomo: 'https://github.com/MetaCubeX/mihomo',
  license: 'https://www.gnu.org/licenses/gpl-3.0.html',
);

class SsAboutPage extends ConsumerStatefulWidget {
  const SsAboutPage({super.key});

  @override
  ConsumerState<SsAboutPage> createState() => _SsAboutPageState();
}

class _SsAboutPageState extends ConsumerState<SsAboutPage> {
  var _taps = 0;

  void _handleMarkTap() {
    if (ref.read(appSettingProvider).developerMode) {
      return;
    }
    if (++_taps < 7) {
      return;
    }
    _taps = 0;
    ref
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(developerMode: true));
    context.showNotifier(
      context.appLocalizations.developerModeEnableTip,
      level: MessageLevel.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final version = globalState.packageInfo.version;
    final build = globalState.packageInfo.buildNumber;
    return SsPage(
      title: l.about,
      children: [
        SsCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: _handleMarkTap,
                child: const SsBrandMark(size: 64),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SsWordmark(type: SsType.title),
                    const SizedBox(height: 4),
                    Text(
                      'v$version · build $build',
                      style: SsType.mono.color(palette.textMuted),
                    ),
                    const SizedBox(height: 8),
                    SsBadge(label: 'GPL-3.0', color: palette.mint),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.ssAboutText,
            style: SsType.body.color(palette.textMuted),
          ),
        ),
        const SizedBox(height: 22),
        SsGroup(
          title: l.ssCredits,
          children: [
            SsRow(
              icon: LucideIcons.heart,
              iconColor: palette.rose,
              title: 'FlClash',
              subtitle: l.ssCreditFlClash,
              trailing: Icon(
                LucideIcons.externalLink,
                size: 16,
                color: palette.textFaint,
              ),
              onTap: () => dialogs.openUrl(_links.flclash),
            ),
            SsRow(
              icon: LucideIcons.cpu,
              iconColor: palette.sky,
              title: 'Mihomo (Clash.Meta)',
              subtitle: l.ssCreditMihomo,
              trailing: Icon(
                LucideIcons.externalLink,
                size: 16,
                color: palette.textFaint,
              ),
              onTap: () => dialogs.openUrl(_links.mihomo),
            ),
            SsRow(
              icon: LucideIcons.gitBranch,
              iconColor: palette.lavender,
              title: l.ssCoreFork,
              subtitle: 'github.com/chen08209/Clash.Meta',
              trailing: Icon(
                LucideIcons.externalLink,
                size: 16,
                color: palette.textFaint,
              ),
              onTap: () => dialogs.openUrl(_links.core),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SsGroup(
          title: l.ssLicense,
          footer: l.ssLicenseDesc,
          children: [
            SsRow(
              icon: LucideIcons.scale,
              iconColor: palette.mint,
              title: 'GNU GPL v3.0',
              trailing: Icon(
                LucideIcons.externalLink,
                size: 16,
                color: palette.textFaint,
              ),
              onTap: () => dialogs.openUrl(_links.license),
            ),
            SsRow(
              icon: LucideIcons.code,
              iconColor: palette.sky,
              title: l.ssSourceCode,
              subtitle: 'github.com/chen08209/FlClash',
              trailing: Icon(
                LucideIcons.externalLink,
                size: 16,
                color: palette.textFaint,
              ),
              onTap: () => dialogs.openUrl(_links.flclash),
            ),
            SsRow(
              icon: LucideIcons.fileText,
              iconColor: palette.lemon,
              title: l.ssOpenSourceLicenses,
              chevron: true,
              onTap: () => showLicensePage(
                context: context,
                applicationName: ssAppName,
                applicationVersion: version,
                applicationLegalese: 'GPL-3.0 · based on FlClash',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
