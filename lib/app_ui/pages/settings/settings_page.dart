import 'package:fl_clash/app_ui/pages/settings/routing_mode.dart';
import 'package:fl_clash/app_ui/pages/settings/about_page.dart';
import 'package:fl_clash/app_ui/pages/settings/advanced_page.dart';
import 'package:fl_clash/app_ui/pages/settings/appearance.dart';
import 'package:fl_clash/app_ui/shell/shell.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/layout.dart';
import 'package:fl_clash/app_ui/widgets/page.dart';
import 'package:fl_clash/app_ui/widgets/reveal.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/ui.dart' show BaseNavigator;
import 'package:fl_clash/views/views.dart' show AccessView, BackupAndRestore;
import 'package:fl_clash/views/config/on_demand.dart' show OnDemandView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SsSettingsPage extends ConsumerWidget {
  const SsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final top = MediaQuery.paddingOf(context).top;
    final side = ssSidePadding(context);
    final bottom = SsShellInsets.bottomOf(context);
    final settings = ref.watch(appSettingProvider);
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final accessControl = ref.watch(
      vpnSettingProvider.select((state) => state.accessControlProps),
    );
    final locale = getLocaleForString(settings.locale);
    void updateApp(AppSettingProps Function(AppSettingProps) change) =>
        ref.read(appSettingProvider.notifier).update(change);
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
                  SsRun(l.ssSettingsLead),
                  SsRun.accent(l.ssSettingsAccent, color: palette.peach),
                ], type: SsType.title),
              ),
              const SizedBox(height: 22),
              SsReveal(
                index: i++,
                child: SsGroup(
                  title: l.ssBasics,
                  children: [
                    SsRow(
                      icon: LucideIcons.palette,
                      iconColor: palette.lavender,
                      title: l.ssAppearance,
                      value: themeModeLabel(l, themeMode),
                      chevron: true,
                      onTap: () => showAppearanceSheet(context),
                    ),
                    SsRow(
                      icon: LucideIcons.languages,
                      iconColor: palette.sky,
                      title: l.language,
                      value: locale?.label ?? l.defaultText,
                      chevron: true,
                      onTap: () => showLanguageSheet(context),
                    ),
                    SsRow(
                      icon: LucideIcons.appWindow,
                      iconColor: palette.mint,
                      title: l.ssSplitTunneling,
                      subtitle: l.ssSplitTunnelingDesc,
                      value: accessControl.enable ? l.ssOn : l.ssOff,
                      chevron: true,
                      onTap: () =>
                          BaseNavigator.push(context, const AccessView()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SsReveal(index: i++, child: const SsRoutingModeSettings()),
              const SizedBox(height: 22),
              SsReveal(
                index: i++,
                child: SsGroup(
                  title: l.ssLaunch,
                  footer: l.autoRunDesc,
                  children: [
                    SsSwitchRow(
                      icon: LucideIcons.rocket,
                      iconColor: palette.lemon,
                      title: l.autoRun,
                      value: settings.autoRun,
                      onChanged: (value) =>
                          updateApp((state) => state.copyWith(autoRun: value)),
                    ),
                    SsRow(
                      icon: LucideIcons.wifi,
                      iconColor: palette.sky,
                      title: l.onDemand,
                      subtitle: l.onDemandDesc,
                      chevron: true,
                      onTap: () =>
                          BaseNavigator.push(context, const OnDemandView()),
                    ),
                    SsSwitchRow(
                      icon: LucideIcons.eyeOff,
                      iconColor: palette.peach,
                      title: l.exclude,
                      value: settings.hidden,
                      onChanged: (value) =>
                          updateApp((state) => state.copyWith(hidden: value)),
                    ),
                    SsSwitchRow(
                      icon: LucideIcons.bellRing,
                      iconColor: palette.mint,
                      title: l.showNotificationStopAction,
                      value: settings.showNotificationStopAction,
                      onChanged: (value) => updateApp(
                        (state) =>
                            state.copyWith(showNotificationStopAction: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SsReveal(
                index: i++,
                child: SsGroup(
                  title: l.ssMore,
                  children: [
                    SsRow(
                      icon: LucideIcons.wrench,
                      iconColor: palette.lavender,
                      title: l.ssAdvanced,
                      subtitle: l.ssAdvancedDesc,
                      chevron: true,
                      onTap: () =>
                          pushSsPage<void>(context, const SsAdvancedPage()),
                    ),
                    SsRow(
                      icon: LucideIcons.archiveRestore,
                      iconColor: palette.sky,
                      title: l.backupAndRestore,
                      chevron: true,
                      onTap: () =>
                          BaseNavigator.push(context, const BackupAndRestore()),
                    ),
                    SsRow(
                      icon: LucideIcons.info,
                      iconColor: palette.mint,
                      title: l.about,
                      chevron: true,
                      onTap: () =>
                          pushSsPage<void>(context, const SsAboutPage()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
