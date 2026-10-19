import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// A titled group of rows on one bordered card, with an optional footnote.
class SsGroup extends StatelessWidget {
  const SsGroup({super.key, this.title, required this.children, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 60),
            child: Divider(height: 1, thickness: 1, color: palette.border),
          ),
        );
      }
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: SsOverline(title!),
          ),
        SsCard(
          padding: EdgeInsets.zero,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
        if (footer != null && footer!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Text(
              footer!,
              style: SsType.caption.color(palette.textMuted),
            ),
          ),
      ],
    );
  }
}

/// An icon tile at the head of a row.
class SsIconTile extends StatelessWidget {
  const SsIconTile(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final ink = color ?? palette.textMuted;
    return Container(
      width: 32,
      height: 32,
      decoration: ShapeDecoration(
        color: palette.tint(ink, 0.12),
        shape: AppShape.all(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: ink),
    );
  }
}

/// A settings row: icon, title with an optional explanation, and a trailing
/// value, switch or chevron.
class SsRow extends StatelessWidget {
  const SsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.value,
    this.onTap,
    this.chevron = false,
    this.destructive = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final String? value;
  final VoidCallback? onTap;
  final bool chevron;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final titleColor = destructive ? palette.rose : palette.text;
    // Large text leaves the title no room beside the value, so the value
    // moves under it.
    final stackValue =
        value != null && MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            SsIconTile(icon!, color: destructive ? palette.rose : iconColor),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: SsType.body.color(titleColor)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: SsType.caption.color(palette.textMuted),
                  ),
                ],
                if (stackValue) ...[
                  const SizedBox(height: 2),
                  Text(value!, style: SsType.mono.color(palette.accent)),
                ],
              ],
            ),
          ),
          if (value != null && !stackValue) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: SsType.mono.color(palette.textMuted),
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (chevron) ...[
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, size: 18, color: palette.textFaint),
          ],
        ],
      ),
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: onTap == null
          ? body
          : InkWell(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onTap!();
                    }
                  : null,
              child: body,
            ),
    );
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: SsMotion.of(context, SsMotion.fast),
      child: row,
    );
  }
}

/// A row whose trailing switch flips the setting; the whole row is the target.
class SsSwitchRow extends StatelessWidget {
  const SsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SsRow(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        enabled: onChanged != null,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
