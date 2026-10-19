import 'dart:ui' show lerpDouble;

import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class SsNavItem {
  const SsNavItem({required this.icon, required this.label, this.activeIcon});

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

const ssNavBarHeight = 66.0;
const ssNavBarMargin = 14.0;

/// A floating pill navigation bar. Its indicator flows between destinations:
/// the leading edge runs ahead and the trailing edge follows, so it stretches
/// mid-way and settles on arrival.
class SsNavBar extends StatefulWidget {
  const SsNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  final List<SsNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  State<SsNavBar> createState() => _SsNavBarState();
}

class _SsNavBarState extends State<SsNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );
  late double _from = widget.index.toDouble();
  late double _to = widget.index.toDouble();

  static const _lead = Cubic(0.3, 0, 0, 1);
  static const _trail = Cubic(0.6, 0, 0.1, 1);

  double get _position =>
      lerpDouble(_from, _to, SsMotion.emphasized.transform(_controller.value))!;

  @override
  void didUpdateWidget(SsNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _from = _controller.isAnimating ? _position : oldWidget.index.toDouble();
      _to = widget.index.toDouble();
      if (SsMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (double, double) _edges() {
    final t = _controller.value;
    final forward = _to >= _from;
    final leadT = _lead.transform(t);
    final trailT = _trail.transform(t);
    final start = lerpDouble(_from, _to, forward ? trailT : leadT)!;
    final end = lerpDouble(_from, _to, forward ? leadT : trailT)! + 1;
    return (start, end);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final count = widget.items.length;
    return Container(
      height: ssNavBarHeight,
      decoration: ShapeDecoration(
        color: palette.isDark
            ? palette.raised.withValues(alpha: 0.96)
            : palette.raised.withValues(alpha: 0.97),
        shape: AppShape.full.copyWith(
          side: BorderSide(color: palette.borderStrong),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.5 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / count;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final (start, end) = _edges();
                  return PositionedDirectional(
                    start: start * slot,
                    width: (end - start) * slot,
                    top: 0,
                    bottom: 0,
                    child: child!,
                  );
                },
                child: RepaintBoundary(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.tint(
                        palette.accent,
                        palette.isDark ? 0.2 : 0.15,
                      ),
                      shape: AppShape.full.copyWith(
                        side: BorderSide(
                          color: palette.accent.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (i, item) in widget.items.indexed)
                    Expanded(
                      child: _NavButton(
                        item: item,
                        selected: i == widget.index,
                        onTap: () {
                          if (i != widget.index) {
                            HapticFeedback.selectionClick();
                          }
                          widget.onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SsNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final duration = SsMotion.of(context, SsMotion.medium);
    final color = selected ? palette.text : palette.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: duration,
              curve: SsMotion.spring,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: selected ? palette.accent : color),
                duration: duration,
                builder: (_, value, _) => Icon(
                  selected ? item.activeIcon ?? item.icon : item.icon,
                  size: 21,
                  color: value,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: SsType.caption
                      .color(color)
                      .copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                  child: Text(item.label, maxLines: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
