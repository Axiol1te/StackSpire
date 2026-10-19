import 'dart:async';

import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:material_ui/material_ui.dart';

/// Fades its child in while lifting it a few dp, after [index] stagger steps.
/// It plays once per mount, so scrolling a list back does not replay it.
class SsReveal extends StatefulWidget {
  const SsReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<SsReveal> createState() => _SsRevealState();
}

class _SsRevealState extends State<SsReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SsMotion.reveal,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: SsMotion.enter,
  );
  Timer? _delay;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (SsMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    final wait = SsMotion.stagger * widget.index.clamp(0, 12);
    if (wait == Duration.zero) {
      _controller.forward();
    } else {
      _delay = Timer(wait, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
