import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:material_ui/material_ui.dart';

const ssAppName = 'StackSpire';

/// The StackSpire monogram: two italic S, sky over mint, stepped like a
/// stack, on an outlined tile.
class SsBrandMark extends StatelessWidget {
  const SsBrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final glyph = SsType.title.style.copyWith(
      fontSize: size * 0.56,
      height: 1,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      letterSpacing: 0,
    );
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          color: palette.raised,
          shape: AppShape.all(
            size * 0.3,
          ).copyWith(side: BorderSide(color: palette.borderStrong)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(-size * 0.1, -size * 0.04),
              child: Text('S', style: glyph.copyWith(color: palette.sky)),
            ),
            Transform.translate(
              offset: Offset(size * 0.12, size * 0.06),
              child: Text(
                'S',
                style: glyph.copyWith(
                  color: palette.mint.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Stack" upright, "Spire" in the accent italic.
class SsWordmark extends StatelessWidget {
  const SsWordmark({super.key, this.type = SsType.titleSmall});

  final SsType type;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    return Semantics(
      label: ssAppName,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Stack'),
            TextSpan(
              text: 'Spire',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: palette.lavender,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: type.color(palette.text),
      ),
    );
  }
}
