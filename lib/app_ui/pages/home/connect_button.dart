import 'dart:math' as math;

import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

enum SsConnectState {
  off,
  connecting,
  connected,
  disconnecting,
  suspended,
  unavailable,
}

/// The large connect button. Off it is a quiet outlined disc; connecting, an
/// arc runs round it while rings ripple out; connected, it settles into a
/// soft mint glow. Every transition eases from wherever the last one stopped,
/// so quick repeated taps never jump.
class SsConnectButton extends StatefulWidget {
  const SsConnectButton({
    super.key,
    required this.state,
    required this.onTap,
    required this.semanticLabel,
    this.size = 208,
  });

  final SsConnectState state;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;

  @override
  State<SsConnectButton> createState() => _SsConnectButtonState();
}

class _SsConnectButtonState extends State<SsConnectButton>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _lit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: widget.state == SsConnectState.connected ? 1 : 0,
  );
  late final AnimationController _busy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: _isBusy ? 1 : 0,
  );
  var _pressed = false;

  bool get _isBusy =>
      widget.state == SsConnectState.connecting ||
      widget.state == SsConnectState.disconnecting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SsConnectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == SsConnectState.connected) {
        HapticFeedback.mediumImpact();
      }
      _sync();
    }
  }

  void _sync() {
    final reduced = SsMotion.reduced(context);
    final connecting = _isBusy;
    final connected = widget.state == SsConnectState.connected;
    if (reduced) {
      _spin.stop();
      _wave.stop();
      _lit.value = connected ? 1 : 0;
      _busy.value = connecting ? 1 : 0;
      return;
    }
    if (connecting) {
      if (!_spin.isAnimating) _spin.repeat();
      if (!_wave.isAnimating) _wave.repeat();
    } else {
      _spin.stop();
      _wave.stop();
    }
    _busy.animateTo(connecting ? 1 : 0, curve: SsMotion.enter);
    _lit.animateTo(
      connected ? 1 : 0,
      curve: connected ? SsMotion.spring : SsMotion.exit,
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    _wave.dispose();
    _lit.dispose();
    _busy.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.state) {
    SsConnectState.connected => LucideIcons.shieldCheck,
    SsConnectState.suspended => LucideIcons.pause,
    SsConnectState.unavailable => LucideIcons.plus,
    _ => LucideIcons.power,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final size = widget.size;
    final enabled = widget.onTap != null;
    final iconColor = switch (widget.state) {
      SsConnectState.connected => palette.mint,
      SsConnectState.connecting => palette.accent,
      SsConnectState.suspended => palette.lemon,
      _ => palette.text,
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.heavyImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: SsMotion.of(context, SsMotion.fast),
          curve: SsMotion.enter,
          child: SizedBox.square(
            dimension: size + 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size.square(size + 56),
                    painter: _ConnectPainter(
                      spin: _spin,
                      wave: _wave,
                      lit: _lit,
                      busy: _busy,
                      palette: palette,
                      radius: size / 2,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: SsMotion.of(context, SsMotion.slow),
                  switchInCurve: SsMotion.spring,
                  switchOutCurve: SsMotion.exit,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(animation),
                      child: RotationTransition(
                        turns: Tween(begin: -0.08, end: 0.0).animate(animation),
                        child: child,
                      ),
                    ),
                  ),
                  child: TweenAnimationBuilder<Color?>(
                    key: ValueKey(_icon),
                    tween: ColorTween(end: iconColor),
                    duration: SsMotion.of(context, SsMotion.medium),
                    builder: (_, color, _) =>
                        Icon(_icon, size: size * 0.2, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectPainter extends CustomPainter {
  _ConnectPainter({
    required this.spin,
    required this.wave,
    required this.lit,
    required this.busy,
    required this.palette,
    required this.radius,
  }) : super(repaint: Listenable.merge([spin, wave, lit, busy]));

  final Animation<double> spin;
  final Animation<double> wave;
  final Animation<double> lit;
  final Animation<double> busy;
  final SsPalette palette;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final l = lit.value.clamp(0.0, 1.2);
    final b = busy.value;
    final glowColor = Color.lerp(palette.accent, palette.mint, l.clamp(0, 1))!;

    if (l > 0) {
      canvas.drawCircle(
        center,
        radius * 1.32,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  palette.mint.withValues(alpha: 0.26 * l.clamp(0, 1)),
                  palette.mint.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: center, radius: radius * 1.32),
              ),
      );
    }

    if (b > 0) {
      for (var i = 0; i < 2; i++) {
        final t = (wave.value + i * 0.5) % 1;
        final r = radius * (0.78 + 0.5 * t);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = palette.accent.withValues(alpha: 0.4 * (1 - t) * b),
        );
      }
    }

    final discRadius = radius * 0.78;
    final disc = Color.lerp(
      palette.raised,
      palette.tint(palette.mint, palette.isDark ? 0.14 : 0.16),
      l.clamp(0, 1),
    )!;
    canvas.drawCircle(center, discRadius, Paint()..color = disc);
    canvas.drawCircle(
      center,
      discRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.lerp(
          palette.borderStrong,
          palette.mint.withValues(alpha: 0.5),
          l.clamp(0, 1),
        )!,
    );

    final ringRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = palette.border,
    );
    if (l > 0) {
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        math.pi * 2 * l.clamp(0, 1),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = glowColor,
      );
    }
    if (b > 0) {
      final start = spin.value * math.pi * 2 - math.pi / 2;
      canvas.drawArc(
        ringRect,
        start,
        math.pi * 0.55,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = palette.accent.withValues(alpha: b),
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.radius != radius;
}
