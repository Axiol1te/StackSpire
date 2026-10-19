import 'dart:async';

import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/sheet.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/profiles/custom/custom.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

enum SsAddMethod {
  link(LucideIcons.link),
  clipboard(LucideIcons.clipboardPaste),
  qr(LucideIcons.scanQrCode),
  file(LucideIcons.fileUp),
  custom(LucideIcons.slidersHorizontal);

  const SsAddMethod(this.icon);

  final IconData icon;

  static const quick = [clipboard, qr, file];

  String label(AppLocalizations l) => switch (this) {
    link => l.importFromLink,
    clipboard => l.ssFromClipboard,
    qr => l.qrcode,
    file => l.file,
    custom => l.customProfile,
  };

  String description(AppLocalizations l) => switch (this) {
    link => l.linkDesc,
    clipboard => l.ssFromClipboardDesc,
    qr => l.qrcodeDesc,
    file => l.fileDesc,
    custom => l.customProfileDesc,
  };

  Color color(SsPalette palette) => switch (this) {
    link => palette.sky,
    clipboard => palette.mint,
    qr => palette.lemon,
    file => palette.peach,
    custom => palette.lavender,
  };
}

Future<void> showSsAddProfileSheet(BuildContext context) {
  return showSsSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l = sheetContext.appLocalizations;
      final palette = sheetContext.ss;
      return SsSheetFrame(
        title: l.ssAddSubscription,
        subtitle: l.ssAddSubscriptionHint,
        child: SingleChildScrollView(
          child: SsGroup(
            children: [
              for (final method in SsAddMethod.values)
                SsRow(
                  icon: method.icon,
                  iconColor: method.color(palette),
                  title: method.label(l),
                  subtitle: method.description(l),
                  chevron: true,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 120),
                    );
                    if (context.mounted) {
                      await runSsAddMethod(context, method);
                    }
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> runSsAddMethod(BuildContext context, SsAddMethod method) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final actions = container.read(profilesActionProvider.notifier);
  switch (method) {
    case SsAddMethod.link:
      await _addFromLinkForm(context, container);
    case SsAddMethod.clipboard:
      await _addFromClipboard(context, actions);
    case SsAddMethod.qr:
      if (system.isDesktop) {
        unawaited(actions.addProfileFormQrCode());
        return;
      }
      final url = await Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const ScanPage()));
      if (url != null && url.isNotEmpty) {
        unawaited(actions.addProfileFromLink(url));
      }
    case SsAddMethod.file:
      unawaited(actions.addProfileFormFile());
    case SsAddMethod.custom:
      final label = context.appLocalizations.unnamed;
      final id = actions.addCustomProfile(label);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CustomProfileView(profileId: id, isNew: true),
        ),
      );
  }
}

Future<void> _addFromLinkForm(
  BuildContext context,
  ProviderContainer container,
) async {
  final l = context.appLocalizations;
  final actions = container.read(profilesActionProvider.notifier);
  final res = await showNamedUrlsForm(
    context,
    title: l.importFromLink,
    urlLabel: l.link,
    batchTip: l.batchLinkInputTip,
    urlValidator: (value) {
      if (value == null || value.isEmpty) {
        return l.emptyTip(l.link);
      }
      if (!value.isUrl && !value.isShareLink) {
        return l.invalidLinkTip;
      }
      return null;
    },
    existingUrls: {
      for (final profile in container.read(profilesProvider))
        if (profile.url.isNotEmpty) profile.url,
    },
    withAgeSecretKey: true,
  );
  switch (res) {
    case null:
      return;
    case [final single]:
      unawaited(
        actions.addProfileFromLink(
          single.url,
          label: single.label,
          ageSecretKey: single.ageSecretKey,
        ),
      );
    default:
      unawaited(
        actions.addProfilesFromLinks([for (final item in res) item.url]),
      );
  }
}

Future<void> _addFromClipboard(
  BuildContext context,
  ProfilesAction actions,
) async {
  final l = context.appLocalizations;
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final links = [
    for (final line in (data?.text ?? '').split(RegExp(r'\s+')))
      if (line.isUrl || line.isShareLink) line.trim(),
  ];
  if (links.isEmpty) {
    dialogs.showNotifier(l.ssClipboardNoLink, level: MessageLevel.warning);
    return;
  }
  if (links.length == 1) {
    unawaited(actions.addProfileFromLink(links.single));
  } else {
    unawaited(actions.addProfilesFromLinks(links));
  }
}
