import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/buttons.dart';
import 'package:fl_clash/app_ui/widgets/spinner.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:material_ui/material_ui.dart';

/// An empty, error or loading placeholder: a mark, a line of text, an action.
class SsStateView extends StatelessWidget {
  const SsStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.color,
    this.dashed = true,
  });

  const SsStateView.loading({super.key, required this.title})
    : icon = null,
      message = null,
      actionLabel = null,
      actionIcon = null,
      onAction = null,
      color = null,
      dashed = false;

  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final tone = color ?? palette.accent;
    return SsCard(
      dashed: dashed,
      raised: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == null)
            SsSpinner(size: 26, color: palette.accent)
          else
            Container(
              width: 52,
              height: 52,
              decoration: ShapeDecoration(
                color: palette.tint(tone, 0.14),
                shape: CircleBorder(
                  side: BorderSide(color: tone.withValues(alpha: 0.3)),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: tone),
            ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: SsType.bodyStrong.color(palette.text),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: SsType.caption.color(palette.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            SsPill(
              label: actionLabel!,
              icon: actionIcon,
              tone: SsPillTone.tonal,
              onTap: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
