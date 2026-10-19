import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/spinner.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:material_ui/material_ui.dart';

enum SsPillTone { outline, accent, tonal, danger }

/// A pill with a hairline outline and the icon on the left.
class SsPill extends StatelessWidget {
  const SsPill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.tone = SsPillTone.outline,
    this.expand = false,
    this.loading = false,
    this.large = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final SsPillTone tone;
  final bool expand;
  final bool loading;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final enabled = onTap != null && !loading;
    final (fill, ink, side) = switch (tone) {
      SsPillTone.outline => (
        palette.ground,
        palette.text,
        palette.borderStrong,
      ),
      SsPillTone.accent => (palette.accent, palette.onAccent, palette.accent),
      SsPillTone.tonal => (
        palette.tint(palette.accent, 0.16),
        palette.text,
        palette.tint(palette.accent, 0.3),
      ),
      SsPillTone.danger => (
        palette.tint(palette.rose, 0.14),
        palette.rose,
        palette.tint(palette.rose, 0.3),
      ),
    };
    final height = large ? 54.0 : 42.0;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SsSpinner(size: 16, color: ink)
        else if (icon != null)
          Icon(icon, size: large ? 20 : 17, color: ink),
        if (loading || icon != null) const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (large ? SsType.bodyStrong : SsType.label).color(ink),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SsPressable(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled || loading ? 1 : 0.45,
          duration: SsMotion.of(context, SsMotion.fast),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: fill,
                shape: AppShape.full.copyWith(side: BorderSide(color: side)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: large ? 22 : 16,
                  vertical: 8,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round outlined icon button; the tooltip doubles as its accessible name.
class SsIconButton extends StatelessWidget {
  const SsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
    this.color,
    this.busy = false,
    this.outlined = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final bool busy;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final ink = color ?? palette.text;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SsPressable(
          onTap: busy ? null : onTap,
          scale: 0.9,
          child: SizedBox.square(
            dimension: size < 44 ? 44 : size,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: ShapeDecoration(
                  shape: AppShape.full.copyWith(
                    side: outlined
                        ? BorderSide(color: palette.border)
                        : BorderSide.none,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: SsMotion.of(context, SsMotion.fast),
                  child: busy
                      ? SsSpinner(
                          key: const ValueKey('busy'),
                          size: size * 0.42,
                          color: ink,
                        )
                      : Icon(
                          icon,
                          key: ValueKey(icon),
                          size: size * 0.45,
                          color: onTap == null ? palette.textFaint : ink,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
