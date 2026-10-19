import 'package:material_ui/material_ui.dart';

abstract final class SsFonts {
  static const display = 'Montserrat';
  static const body = 'Manrope';
  static const mono = 'JetBrainsMono';

  /// Bundled flags and emoji, which the text faces lack.
  static const fallback = ['Twemoji'];
}

/// StackSpire type roles. Headlines are set in the display face with accent
/// words in its italic; every figure (ping, speed, timer, IP) is monospaced.
enum SsType {
  hero(SsFonts.display, 32, 38, FontWeight.w700, -0.6),
  title(SsFonts.display, 24, 30, FontWeight.w600, -0.3),
  titleSmall(SsFonts.display, 19, 24, FontWeight.w600, -0.2),
  body(SsFonts.body, 15, 21, FontWeight.w500, 0),
  bodyStrong(SsFonts.body, 15, 21, FontWeight.w700, 0),
  label(SsFonts.body, 13, 17, FontWeight.w600, 0.1),
  caption(SsFonts.body, 12.5, 16, FontWeight.w500, 0.1),
  monoLarge(SsFonts.mono, 30, 34, FontWeight.w600, -0.5),
  monoTitle(SsFonts.mono, 19, 24, FontWeight.w500, 0),
  mono(SsFonts.mono, 13, 18, FontWeight.w500, 0),
  monoSmall(SsFonts.mono, 11, 14, FontWeight.w500, 0.8);

  const SsType(
    this.family,
    this.size,
    this.leading,
    this.weight,
    this.tracking,
  );

  final String family;
  final double size;
  final double leading;
  final FontWeight weight;
  final double tracking;

  TextStyle get style => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: leading / size,
    fontWeight: weight,
    letterSpacing: tracking,
    fontFamilyFallback: SsFonts.fallback,
    fontFeatures: family == SsFonts.mono
        ? const [FontFeature.tabularFigures()]
        : const [FontFeature.liningFigures()],
  );

  TextStyle color(Color color) => style.copyWith(color: color);

  TextStyle get italic => style.copyWith(fontStyle: FontStyle.italic);
}

extension SsTextStyleExt on TextStyle {
  TextStyle get emphasized => copyWith(fontWeight: FontWeight.w700);

  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
}

/// Display face on the slots Material and the shared components read for
/// titles, the body face everywhere else.
TextTheme ssTextTheme(TextTheme base) {
  TextStyle? display(TextStyle? style) =>
      style?.copyWith(fontFamily: SsFonts.display, letterSpacing: -0.3);
  return base
      .apply(fontFamily: SsFonts.body)
      .copyWith(
        displayLarge: display(base.displayLarge),
        displayMedium: display(base.displayMedium),
        displaySmall: display(base.displaySmall),
        headlineLarge: display(base.headlineLarge),
        headlineMedium: display(base.headlineMedium),
        headlineSmall: display(base.headlineSmall),
      );
}
