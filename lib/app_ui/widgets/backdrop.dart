import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:material_ui/material_ui.dart';

/// The warm ground with a fine grid that fades out down the screen.
class SsBackdrop extends StatelessWidget {
  const SsBackdrop({super.key, required this.child, this.grid = true});

  final Widget child;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    return ColoredBox(
      color: palette.ground,
      child: Stack(
        children: [
          if (grid)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GridPainter(
                    line: palette.grid,
                    ground: palette.ground,
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.line, required this.ground});

  final Color line;
  final Color ground;

  static const _cell = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    final fadeEnd = size.height * 0.75;
    final rect = Offset.zero & Size(size.width, fadeEnd);
    canvas.saveLayer(rect, Paint());
    for (var x = _cell / 2; x < size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, fadeEnd), paint);
    }
    for (var y = _cell / 2; y < fadeEnd; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final fade = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ground,
          ground.withValues(alpha: 0.55),
          ground.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, fade);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.ground != ground;
}
