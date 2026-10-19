import 'package:material_ui/material_ui.dart';

abstract final class SsMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const reveal = Duration(milliseconds: 520);

  /// Gap between items of a cascading entrance.
  static const stagger = Duration(milliseconds: 55);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const spring = Curves.easeOutBack;

  /// Whether the system asks for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or nothing when the system asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
