import 'package:animations/animations.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';

const _actionIconTheme = ActionIconThemeData(
  backButtonIconBuilder: _backButtonIcon,
  closeButtonIconBuilder: _closeButtonIcon,
);

Widget _backButtonIcon(BuildContext context) =>
    GlyphIcon(AppGlyphs.backFor(Theme.of(context).platform));

Widget _closeButtonIcon(BuildContext context) =>
    const GlyphIcon(AppGlyphs.close);

ColorScheme _colorScheme(SsPalette p) {
  final dark = p.isDark;
  return ColorScheme(
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.tint(p.accent, 0.2),
    onPrimaryContainer: p.text,
    secondary: p.mint,
    onSecondary: p.onAccent,
    secondaryContainer: p.tint(p.mint, 0.18),
    onSecondaryContainer: p.text,
    tertiary: p.lavender,
    onTertiary: p.onAccent,
    tertiaryContainer: p.tint(p.lavender, 0.18),
    onTertiaryContainer: p.text,
    error: p.rose,
    onError: p.onAccent,
    errorContainer: p.tint(p.rose, 0.2),
    onErrorContainer: p.text,
    surface: p.ground,
    onSurface: p.text,
    onSurfaceVariant: p.textMuted,
    surfaceDim: dark ? p.ground : p.inset,
    surfaceBright: dark ? const Color(0xFF2A2522) : p.raised,
    surfaceContainerLowest: dark ? const Color(0xFF080706) : Colors.white,
    surfaceContainerLow: dark
        ? const Color(0xFF100E0C)
        : const Color(0xFFF3EFEA),
    surfaceContainer: dark ? p.raised : p.ground,
    surfaceContainerHigh: dark ? p.raisedHigh : p.raisedHigh,
    surfaceContainerHighest: p.inset,
    outline: dark ? const Color(0xFF4A4440) : const Color(0xFF8F877F),
    outlineVariant: dark ? const Color(0xFF2A2522) : const Color(0xFFDCD5CC),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: p.text,
    onInverseSurface: p.ground,
    inversePrimary: dark ? SsPalette.light.accent : SsPalette.dark.accent,
    surfaceTint: Colors.transparent,
  );
}

final _themes = <Brightness, ThemeData>{};

/// The StackSpire theme. Shared components from lib/ui read the same colour
/// scheme, so every screen follows it.
ThemeData ssTheme(Brightness brightness) {
  return _themes[brightness] ??= _buildTheme(brightness);
}

ThemeData _buildTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark
      ? SsPalette.dark
      : SsPalette.light;
  final colorScheme = _colorScheme(palette);
  final transitions = SharedAxisPageTransitionsBuilder(
    transitionType: SharedAxisTransitionType.horizontal,
    fillColor: palette.ground,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: SsFonts.body,
    fontFamilyFallback: SsFonts.fallback,
    platform: defaultTargetPlatform,
    actionIconTheme: _actionIconTheme,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.macOS: transitions,
      },
    ),
    extensions: [
      palette,
      if (brightness == Brightness.dark)
        ElevatedColorScheme(colorScheme.elevated),
    ],
  ).withAppShapes.withAppSurfaces.withAppTypography;
  return base.copyWith(
    textTheme: ssTextTheme(base.textTheme),
    primaryTextTheme: ssTextTheme(base.primaryTextTheme),
    scaffoldBackgroundColor: palette.ground,
    canvasColor: palette.ground,
    dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : palette.borderStrong,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.onAccent
            : palette.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.raisedHigh,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.raisedHigh,
      contentTextStyle: SsType.body.color(palette.text),
      shape: AppShape.all(14).copyWith(side: BorderSide(color: palette.border)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.raisedHigh,
    ),
  );
}
