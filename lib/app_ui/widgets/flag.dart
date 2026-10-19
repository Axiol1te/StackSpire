import 'package:emoji_regex/emoji_regex.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:fl_clash/ui/text_style.dart' show FontFamily;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

final _regionalFlag = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);

/// The flag a node's name leads with, if any, else its first emoji.
String? _leadingEmoji(String name) {
  final flag = _regionalFlag.firstMatch(name);
  if (flag != null) {
    return flag.group(0);
  }
  final emoji = emojiRegex().firstMatch(name);
  if (emoji != null && emoji.start <= 2) {
    return emoji.group(0);
  }
  return null;
}

/// [name] without the flag it leads with, which [SsFlag] already shows.
String ssDisplayName(String name) {
  final flag = _regionalFlag.firstMatch(name);
  if (flag == null || flag.start > 2) {
    return name;
  }
  final rest = name.replaceRange(flag.start, flag.end, '').trim();
  return rest.isEmpty ? name : rest;
}

/// A round tile showing a node's flag (or its initial) by its name; null
/// shows the direct-route mark.
class SsFlag extends StatelessWidget {
  const SsFlag({super.key, required this.name, this.size = 36});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    final emoji = name == null ? null : _leadingEmoji(name!);
    final initial = name == null || name!.trim().isEmpty
        ? '?'
        : name!.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          color: palette.raisedHigh,
          shape: AppShape.all(
            size * 0.32,
          ).copyWith(side: BorderSide(color: palette.border)),
        ),
        alignment: Alignment.center,
        child: name == null
            ? Icon(
                LucideIcons.arrowRight,
                size: size * 0.45,
                color: palette.mint,
              )
            : emoji != null
            ? Text(
                emoji,
                style: TextStyle(
                  fontFamily: FontFamily.twEmoji.value,
                  fontSize: size * 0.5,
                  height: 1,
                ),
              )
            : Text(initial, style: SsType.bodyStrong.color(palette.textMuted)),
      ),
    );
  }
}

/// A country flag from an ISO code.
class SsCountryFlag extends StatelessWidget {
  const SsCountryFlag({super.key, required this.code, this.size = 24});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        code.countryFlagEmoji,
        style: TextStyle(
          fontFamily: FontFamily.twEmoji.value,
          fontSize: size,
          height: 1,
        ),
      ),
    );
  }
}
