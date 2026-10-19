import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:material_ui/material_ui.dart';

/// Opens a bottom sheet that rises with a soft overshoot and closes quickly.
Future<T?> showSsSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool scrollable = true,
}) {
  final palette = context.ss;
  final reduced = SsMotion.reduced(context);
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: scrollable,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: palette.raised,
    barrierColor: Colors.black.withValues(alpha: palette.isDark ? 0.6 : 0.32),
    shape: AppShape.top(26).copyWith(side: BorderSide(color: palette.border)),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: reduced
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 460),
            reverseDuration: Duration(milliseconds: 240),
            curve: Cubic(0.18, 1.25, 0.4, 1),
            reverseCurve: SsMotion.exit,
          ),
    builder: builder,
  );
}

/// The frame of a sheet: grabber, title and padded content.
class SsSheetFrame extends StatelessWidget {
  const SsSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 36,
              height: 4,
              decoration: ShapeDecoration(
                color: palette.borderStrong,
                shape: AppShape.full,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: SsType.titleSmall.color(palette.text),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: SsType.caption.color(palette.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Flexible(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}
