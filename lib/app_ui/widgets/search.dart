import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

/// A pill search field bound to one of the app's query providers.
class SsSearchField extends ConsumerStatefulWidget {
  const SsSearchField({super.key, required this.tag, required this.hint});

  final QueryTag tag;
  final String hint;

  @override
  ConsumerState<SsSearchField> createState() => _SsSearchFieldState();
}

class _SsSearchFieldState extends ConsumerState<SsSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(queryProvider(widget.tag)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String value) {
    ref.read(queryProvider(widget.tag).notifier).value = value;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.ss;
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (_, value, _) => TextField(
        controller: _controller,
        onChanged: _set,
        autocorrect: false,
        textInputAction: TextInputAction.search,
        style: SsType.body.color(palette.text),
        cursorColor: palette.accent,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: palette.raised,
          hintText: widget.hint,
          hintStyle: SsType.body.color(palette.textMuted),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: palette.textMuted,
          ),
          suffixIcon: AnimatedOpacity(
            opacity: value.text.isEmpty ? 0 : 1,
            duration: SsMotion.of(context, SsMotion.fast),
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: Icon(LucideIcons.x, size: 18, color: palette.textMuted),
              onPressed: value.text.isEmpty
                  ? null
                  : () {
                      _controller.clear();
                      _set('');
                    },
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: AppInputBorder(
            borderRadius: AppRadius.full,
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: AppInputBorder(
            borderRadius: AppRadius.full,
            borderSide: BorderSide(color: palette.border),
          ),
          focusedBorder: AppInputBorder(
            borderRadius: AppRadius.full,
            borderSide: BorderSide(
              color: palette.accent.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class SsProxySearchField extends StatelessWidget {
  const SsProxySearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return SsSearchField(
      tag: QueryTag.proxies,
      hint: context.appLocalizations.ssSearchServers,
    );
  }
}
