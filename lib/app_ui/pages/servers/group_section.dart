import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/delay.dart';
import 'package:fl_clash/app_ui/widgets/flag.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SsNodeTile extends ConsumerWidget {
  const SsNodeTile({
    super.key,
    required this.group,
    required this.proxy,
    required this.onTap,
    required this.inUse,
  });

  final Group group;
  final Proxy proxy;
  final VoidCallback onTap;
  final bool inUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.ss;
    final pinned =
        group.type.isComputedSelected &&
        ref.watch(
          proxyNameProvider(group.name).select((name) => name == proxy.name),
        );
    final duration = SsMotion.of(context, SsMotion.medium);
    final accent = palette.accent;
    return Semantics(
      selected: inUse,
      button: true,
      label: proxy.name,
      child: AnimatedContainer(
        duration: duration,
        curve: SsMotion.emphasized,
        decoration: ShapeDecoration(
          color: inUse
              ? palette.tint(accent, palette.isDark ? 0.12 : 0.1)
              : palette.ground,
          shape: AppShape.all(14).copyWith(
            side: BorderSide(
              color: inUse ? accent.withValues(alpha: 0.5) : palette.border,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: AppShape.all(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                child: Row(
                  children: [
                    SsFlag(name: proxy.name, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ssDisplayName(proxy.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SsType.body.color(palette.text),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            proxy.type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SsType.monoSmall.color(palette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (pinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          LucideIcons.pin,
                          size: 14,
                          color: palette.lemon,
                        ),
                      ),
                    SsDelayBadge(proxyName: proxy.name, testUrl: group.testUrl),
                    SizedBox(
                      width: 26,
                      child: AnimatedSwitcher(
                        duration: duration,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: SsMotion.spring,
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: inUse
                            ? Icon(
                                LucideIcons.circleCheck,
                                key: const ValueKey(true),
                                size: 18,
                                color: accent,
                              )
                            : const SizedBox(key: ValueKey(false)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
