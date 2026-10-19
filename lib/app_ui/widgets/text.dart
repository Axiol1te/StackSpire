import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:material_ui/material_ui.dart';

/// One run of a [SsHeadline]; an accent run is set in italic pastel.
class SsRun {
  const SsRun(this.text) : color = null, accent = false;

  const SsRun.accent(this.text, {this.color}) : accent = true;

  final String text;
  final Color? color;
  final bool accent;
}

/// A large display headline whose accent words go italic and pastel.
class SsHeadline extends StatelessWidget {
  const SsHeadline(
    this.runs, {
    super.key,
    this.type = SsType.hero,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  final List<SsRun> runs;
  final SsType type;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final base = type.color(palette.text);
    return Text.rich(
      TextSpan(
        children: [
          for (final run in runs)
            TextSpan(
              text: run.text,
              style: run.accent
                  ? base.copyWith(
                      fontStyle: FontStyle.italic,
                      color: run.color ?? palette.accent,
                    )
                  : null,
            ),
        ],
      ),
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// A small monospaced overline such as `// сервер`.
class SsOverline extends StatelessWidget {
  const SsOverline(this.text, {super.key, this.color, this.trailing});

  final String text;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final label = Text(
      '// ${text.toLowerCase()}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: SsType.monoSmall.color(color ?? palette.textMuted),
    );
    if (trailing == null) {
      return Semantics(header: true, child: label);
    }
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: label)),
        trailing!,
      ],
    );
  }
}

/// A quiet tinted pill for statuses and figures.
class SsBadge extends StatelessWidget {
  const SsBadge({
    super.key,
    required this.label,
    required this.color,
    this.mono = true,
    this.dot = false,
    this.icon,
  });

  final String label;
  final Color color;
  final bool mono;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.tint(color, palette.isDark ? 0.13 : 0.12),
        shape: AppShape.full.copyWith(
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: ShapeDecoration(
                  color: color,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (mono ? SsType.monoSmall : SsType.caption).color(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
