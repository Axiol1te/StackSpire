import 'dart:async';
import 'dart:math' as math;

import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/buttons.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/sheet.dart';
import 'package:fl_clash/app_ui/widgets/spinner.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart' show BaseNavigator, showExtend;
import 'package:fl_clash/ui/shape.dart';
import 'package:fl_clash/views/profiles/custom/custom.dart';
import 'package:fl_clash/views/profiles/edit.dart';
import 'package:fl_clash/views/profiles/extend/extend.dart';
import 'package:fl_clash/views/profiles/preview.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SsProfileCard extends ConsumerWidget {
  const SsProfileCard({
    super.key,
    required this.profile,
    required this.selected,
  });

  final Profile profile;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.ss;
    final l = context.appLocalizations;
    final updating = ref.watch(isUpdatingProvider(profile.updatingKey));
    final duration = SsMotion.of(context, SsMotion.medium);
    return Semantics(
      selected: selected,
      button: true,
      label: profile.displayLabel,
      child: AnimatedContainer(
        duration: duration,
        curve: SsMotion.emphasized,
        decoration: ShapeDecoration(
          color: selected
              ? palette.tint(palette.mint, palette.isDark ? 0.08 : 0.08)
              : palette.raised,
          shape: AppShape.all(18).copyWith(
            side: BorderSide(
              color: selected
                  ? palette.mint.withValues(alpha: 0.45)
                  : palette.border,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: AppShape.all(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(currentProfileIdProvider.notifier).value = profile.id;
            },
            onLongPress: () => showProfileActions(context, ref, profile),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SsType.bodyStrong.color(palette.text),
                        ),
                      ),
                      if (updating)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: SsSpinner(size: 18, color: palette.accent),
                        )
                      else
                        Visibility(
                          visible: selected,
                          maintainSize: true,
                          maintainState: true,
                          maintainAnimation: true,
                          child: SsIconButton(
                            icon: LucideIcons.ellipsisVertical,
                            tooltip: l.more,
                            outlined: false,
                            size: 32,
                            onTap: () =>
                                showProfileActions(context, ref, profile),
                          ),
                        ),
                    ],
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: selected ? 1 : 0,
                      end: selected ? 1 : 0,
                    ),
                    duration: SsMotion.of(context, SsMotion.slow),
                    curve: SsMotion.enter,
                    builder: (_, value, child) => ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: value,
                        child: Offstage(
                          offstage: value == 0,
                          child: IgnorePointer(
                            ignoring: !selected,
                            child: ExcludeSemantics(
                              excluding: !selected,
                              child: Opacity(opacity: value, child: child),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        right: 10,
                        bottom: 4,
                      ),
                      child: _SubscriptionDetails(profile: profile),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionDetails extends StatelessWidget {
  const _SubscriptionDetails({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final l = context.appLocalizations;
    final info = profile.subscriptionInfo;
    final expire = info?.expireDate;
    final daysLeft = expire == null
        ? null
        : math.max(0, expire.difference(DateTime.now()).inDays);
    final used = info == null ? 0 : info.upload + info.download;
    final unlimited = info != null && info.hasTotal && info.total == 0;
    final refill = profile.subscriptionRefillDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (daysLeft != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: SsBadge(
              label: l.profileDaysLeft(daysLeft),
              color: daysLeft <= 7 ? palette.peach : palette.mint,
              mono: false,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (info == null || !info.hasUsage)
          Text(
            l.ssTrafficUnavailable,
            style: SsType.caption.color(palette.textMuted),
          )
        else
          Semantics(
            label: unlimited
                ? '${l.usedTraffic}: ${used.traffic.show}, ${l.ssTrafficUnlimited}'
                : '${l.usedTraffic}: ${used.traffic.show}',
            child: Row(
              children: [
                Text(
                  used.traffic.show,
                  style: SsType.monoSmall.color(palette.text),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRSuperellipse(
                      borderRadius: AppRadius.full,
                      child: LinearProgressIndicator(
                        key: info.hasTotal
                            ? ValueKey('subscription-usage-${profile.id}')
                            : null,
                        value: info.usage ?? 0,
                        minHeight: 6,
                        color: (info.usage ?? 0) >= 0.9
                            ? palette.rose
                            : palette.mint,
                        backgroundColor: palette.mint.withValues(
                          alpha: palette.isDark ? 0.22 : 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  unlimited
                      ? '∞'
                      : info.hasTotal
                      ? info.total.traffic.show
                      : '—',
                  style: SsType.mono.color(
                    unlimited ? palette.mint : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        if (refill != null) ...[
          const SizedBox(height: 8),
          Text(
            l.ssTrafficResets(
              MaterialLocalizations.of(context).formatShortDate(
                DateTime.fromMillisecondsSinceEpoch(refill * 1000),
              ),
            ),
            style: SsType.caption.color(palette.textMuted),
          ),
        ],
      ],
    );
  }
}

Future<void> showProfileActions(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) {
  final isUrl = profile.type == ProfileType.url;
  final isCustom = profile.type == ProfileType.custom;
  return showSsSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l = sheetContext.appLocalizations;
      final palette = sheetContext.ss;
      void run(void Function() action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      return SsSheetFrame(
        title: profile.displayLabel,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SsGroup(
                children: [
                  if (profile.supportUrl case final url?)
                    SsRow(
                      icon: LucideIcons.messageCircle,
                      iconColor: palette.mint,
                      title: l.ssSupport,
                      onTap: () => run(() => dialogs.openUrl(url)),
                    ),
                  if (profile.webPageUrl case final url?)
                    SsRow(
                      icon: LucideIcons.externalLink,
                      iconColor: palette.sky,
                      title: l.ssAccountPage,
                      onTap: () => run(() => dialogs.openUrl(url)),
                    ),
                  if (isUrl)
                    SsRow(
                      icon: LucideIcons.refreshCw,
                      iconColor: palette.mint,
                      title: l.update,
                      onTap: () => run(() => _update(ref, profile)),
                    ),
                  SsRow(
                    icon: LucideIcons.pencil,
                    iconColor: palette.sky,
                    title: l.edit,
                    chevron: true,
                    onTap: () => run(() => _edit(context, profile)),
                  ),
                  if (isCustom)
                    SsRow(
                      icon: LucideIcons.textCursorInput,
                      iconColor: palette.sky,
                      title: l.rename,
                      onTap: () =>
                          run(() => renameProfile(context, ref, profile)),
                    )
                  else
                    SsRow(
                      icon: LucideIcons.puzzle,
                      iconColor: palette.lavender,
                      title: l.extend,
                      subtitle: l.ssExtendDesc,
                      chevron: true,
                      onTap: () => run(
                        () => BaseNavigator.push(
                          context,
                          ExtendView(profileId: profile.id),
                        ),
                      ),
                    ),
                  SsRow(
                    icon: LucideIcons.fileCode,
                    iconColor: palette.lemon,
                    title: l.runtimeConfig,
                    chevron: true,
                    onTap: () => run(
                      () => BaseNavigator.push<String>(
                        context,
                        PreviewProfileView(profile: profile),
                      ),
                    ),
                  ),
                  if (isUrl)
                    SsRow(
                      icon: LucideIcons.copy,
                      iconColor: palette.peach,
                      title: l.copyLink,
                      onTap: () => run(() => _copyLink(context, profile)),
                    ),
                  if (!isCustom)
                    SsRow(
                      icon: LucideIcons.download,
                      iconColor: palette.peach,
                      title: l.exportFile,
                      onTap: () => run(() => _export(context, profile)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SsGroup(
                children: [
                  SsRow(
                    icon: LucideIcons.trash2,
                    title: l.delete,
                    destructive: true,
                    onTap: () => run(() => _delete(context, ref, profile)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _update(WidgetRef ref, Profile profile) async {
  await globalState.safeRun(
    () => ref
        .read(profilesActionProvider.notifier)
        .updateProfile(profile, showLoading: true),
  );
}

void _edit(BuildContext context, Profile profile) {
  if (profile.type == ProfileType.custom) {
    unawaited(
      BaseNavigator.push(context, CustomProfileView(profileId: profile.id)),
    );
  } else {
    unawaited(
      showExtend(context, builder: (_) => EditProfileView(profile: profile)),
    );
  }
}

Future<void> _copyLink(BuildContext context, Profile profile) async {
  await Clipboard.setData(ClipboardData(text: profile.url));
  if (context.mounted) {
    context.showNotifier(
      context.appLocalizations.copySuccess,
      level: MessageLevel.success,
    );
  }
}

Future<void> _export(BuildContext context, Profile profile) async {
  final l = context.appLocalizations;
  final res = await globalState.safeRun<bool>(() async {
    final file = await profile.file;
    final value = await picker.saveFile(
      profile.exportFileName,
      file.readAsBytesSync(),
    );
    return value != null;
  }, title: l.tip);
  if (res == true && context.mounted) {
    context.showNotifier(l.exportSuccess, level: MessageLevel.success);
  }
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) async {
  final actions = ref.read(profilesActionProvider.notifier);
  final l = context.appLocalizations;
  final users = await actions.providerUsers(profile);
  final res = await dialogs.showMessage(
    title: l.tip,
    message: TextSpan(
      text: users.isEmpty
          ? l.deleteTip(l.profile)
          : l.providerInUse(
              profile.realLabel,
              users.map((item) => item.realLabel).join(', '),
            ),
    ),
    destructive: true,
    confirmText: l.delete,
  );
  if (res == true) {
    await actions.deleteProfile(profile.id);
  }
}

/// Updates every remote subscription at once.
class SsUpdateAllButton extends ConsumerWidget {
  const SsUpdateAllButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final updating = ref.watch(
      profilesProvider.select(
        (profiles) => profiles.map((profile) => profile.updatingKey).toList(),
      ),
    );
    final busy = updating.any((key) => ref.watch(isUpdatingProvider(key)));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SsSpinner(size: 12, color: palette.accent)
            else
              Icon(LucideIcons.refreshCw, size: 13, color: palette.accent),
            const SizedBox(width: 6),
            Text(l.ssUpdateAll, style: SsType.monoSmall.color(palette.accent)),
          ],
        ),
      ),
    );
  }
}
