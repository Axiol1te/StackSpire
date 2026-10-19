import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/segmented.dart';
import 'package:fl_clash/app_ui/widgets/sheet.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

String themeModeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l.ssThemeSystem,
  ThemeMode.light => l.light,
  ThemeMode.dark => l.dark,
};

Future<void> showAppearanceSheet(BuildContext context) {
  return showSsSheet<void>(
    context: context,
    builder: (_) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final theme = ref.watch(themeSettingProvider);
    void update(ThemeProps Function(ThemeProps) change) =>
        ref.read(themeSettingProvider.notifier).update(change);
    final scale = theme.textScale;
    return SsSheetFrame(
      title: l.ssAppearance,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: SsOverline(l.themeMode),
            ),
            SsSegmented<ThemeMode>(
              value: theme.themeMode,
              onChanged: (value) =>
                  update((state) => state.copyWith(themeMode: value)),
              segments: [
                SsSegment(
                  value: ThemeMode.system,
                  label: l.ssThemeSystem,
                  icon: LucideIcons.smartphone,
                ),
                SsSegment(
                  value: ThemeMode.light,
                  label: l.light,
                  icon: LucideIcons.sun,
                ),
                SsSegment(
                  value: ThemeMode.dark,
                  label: l.dark,
                  icon: LucideIcons.moon,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SsGroup(
              title: l.textScale,
              children: [
                SsSwitchRow(
                  icon: LucideIcons.aLargeSmall,
                  iconColor: palette.lavender,
                  title: l.ssCustomTextScale,
                  subtitle: scale.enable ? null : l.ssTextScaleSystemDesc,
                  value: scale.enable,
                  onChanged: (value) => update(
                    (state) => state.copyWith(
                      textScale: state.textScale.copyWith(enable: value),
                    ),
                  ),
                ),
                if (scale.enable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      children: [
                        Text(
                          'A',
                          style: SsType.caption.color(palette.textMuted),
                        ),
                        Expanded(
                          child: Slider(
                            value: scale.scale.clamp(
                              minTextScale,
                              maxTextScale,
                            ),
                            min: minTextScale,
                            max: maxTextScale,
                            divisions: 6,
                            label: '${(scale.scale * 100).round()}%',
                            onChanged: (value) => update(
                              (state) => state.copyWith(
                                textScale: state.textScale.copyWith(
                                  scale: value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'A',
                          style: SsType.titleSmall.color(palette.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLanguageSheet(BuildContext context) {
  return showSsSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (_, ref, _) {
        final l = sheetContext.appLocalizations;
        final palette = sheetContext.ss;
        final current = ref.watch(
          appSettingProvider.select((state) => state.locale),
        );
        final options = <Locale?>[
          null,
          ...AppLocalizations.delegate.supportedLocales,
        ];
        return SsSheetFrame(
          title: l.language,
          child: SingleChildScrollView(
            child: SsGroup(
              children: [
                for (final locale in options)
                  SsRow(
                    title: locale?.label ?? l.defaultText,
                    trailing: locale?.toString() == current
                        ? Icon(
                            LucideIcons.check,
                            size: 18,
                            color: palette.accent,
                          )
                        : null,
                    onTap: () {
                      ref
                          .read(appSettingProvider.notifier)
                          .update(
                            (state) =>
                                state.copyWith(locale: locale?.toString()),
                          );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
