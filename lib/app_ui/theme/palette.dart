import 'package:material_ui/material_ui.dart';

/// StackSpire colours: a warm near-black (or warm paper) ground, hairline
/// borders, and muted pastel accents used sparingly.
@immutable
class SsPalette extends ThemeExtension<SsPalette> {
  const SsPalette({
    required this.brightness,
    required this.ground,
    required this.raised,
    required this.raisedHigh,
    required this.inset,
    required this.grid,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.mint,
    required this.lemon,
    required this.peach,
    required this.lavender,
    required this.rose,
    required this.sky,
  });

  final Brightness brightness;

  final Color ground;
  final Color raised;
  final Color raisedHigh;
  final Color inset;
  final Color grid;
  final Color border;
  final Color borderStrong;

  final Color text;
  final Color textMuted;

  /// Only for disabled text and decorative marks: it does not meet AA.
  final Color textFaint;

  /// The one colour of primary actions.
  final Color accent;
  final Color onAccent;

  final Color mint;
  final Color lemon;
  final Color peach;
  final Color lavender;
  final Color rose;
  final Color sky;

  bool get isDark => brightness == Brightness.dark;

  Color get connected => mint;
  Color get connecting => accent;
  Color get danger => rose;

  /// A pastel laid over the ground as a quiet fill, for badges and chips.
  Color tint(Color color, [double amount = 0.14]) =>
      Color.alphaBlend(color.withValues(alpha: amount), ground);

  static const dark = SsPalette(
    brightness: Brightness.dark,
    ground: Color(0xFF0C0A09),
    raised: Color(0xFF13110F),
    raisedHigh: Color(0xFF1C1917),
    inset: Color(0xFF221E1C),
    grid: Color(0x0AFFFFFF),
    border: Color(0x1AFFFFFF),
    borderStrong: Color(0x2EFFFFFF),
    text: Color(0xFFF5F5F4),
    textMuted: Color(0xFFA8A29E),
    textFaint: Color(0xFF6B6560),
    accent: Color(0xFFA9D4F5),
    onAccent: Color(0xFF0C0A09),
    mint: Color(0xFFA6E7C6),
    lemon: Color(0xFFF0E39C),
    peach: Color(0xFFF5C2A0),
    lavender: Color(0xFFC8B9F4),
    rose: Color(0xFFE9A2AA),
    sky: Color(0xFFA9D4F5),
  );

  static const light = SsPalette(
    brightness: Brightness.light,
    ground: Color(0xFFF6F3EE),
    raised: Color(0xFFFBF9F6),
    raisedHigh: Color(0xFFEFEBE5),
    inset: Color(0xFFE8E3DC),
    grid: Color(0x0F1C1917),
    border: Color(0x1F1C1917),
    borderStrong: Color(0x331C1917),
    text: Color(0xFF1C1917),
    textMuted: Color(0xFF57534E),
    textFaint: Color(0xFF9C958E),
    accent: Color(0xFF2C6A99),
    onAccent: Color(0xFFFBF9F6),
    mint: Color(0xFF2A7756),
    lemon: Color(0xFF746210),
    peach: Color(0xFF9E5628),
    lavender: Color(0xFF6650AC),
    rose: Color(0xFFAF3F4C),
    sky: Color(0xFF2C6A99),
  );

  static SsPalette of(BuildContext context) =>
      Theme.of(context).extension<SsPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  SsPalette copyWith() => this;

  @override
  SsPalette lerp(SsPalette? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SsPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      ground: mix(ground, other.ground),
      raised: mix(raised, other.raised),
      raisedHigh: mix(raisedHigh, other.raisedHigh),
      inset: mix(inset, other.inset),
      grid: mix(grid, other.grid),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      mint: mix(mint, other.mint),
      lemon: mix(lemon, other.lemon),
      peach: mix(peach, other.peach),
      lavender: mix(lavender, other.lavender),
      rose: mix(rose, other.rose),
      sky: mix(sky, other.sky),
    );
  }
}

extension SsPaletteContext on BuildContext {
  SsPalette get ss => SsPalette.of(this);
}
