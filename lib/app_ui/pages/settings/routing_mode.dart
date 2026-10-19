import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/widgets/rows.dart';
import 'package:fl_clash/app_ui/widgets/segmented.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class SsRoutingModeSettings extends ConsumerWidget {
  const SsRoutingModeSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    return SsGroup(
      title: l.ssRouting,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SsSegmented<Mode>(
            value: mode,
            color: context.ss.sky,
            onChanged: (value) {
              if (ref.read(patchClashConfigProvider).mode != value) {
                ref.read(setupActionProvider.notifier).changeMode(value);
              }
            },
            segments: [
              SsSegment(value: Mode.rule, label: l.ssModeRule),
              SsSegment(value: Mode.global, label: l.global),
              SsSegment(value: Mode.direct, label: l.ssModeDirect),
            ],
          ),
        ),
      ],
    );
  }
}
