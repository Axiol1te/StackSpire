import 'package:fl_clash/app_ui/theme/motion.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/buttons.dart';
import 'package:fl_clash/app_ui/widgets/flag.dart';
import 'package:fl_clash/app_ui/widgets/surface.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/service_probe.dart' show routedOutbound;
import 'package:fl_clash/features/ip_quality/ip_quality.dart';
import 'package:fl_clash/models/models.dart' show IpQuality;
import 'package:fl_clash/providers/ip_quality.dart';
import 'package:fl_clash/providers/outbound_ip.dart';
import 'package:fl_clash/providers/routed_probe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SsYourIpCard extends ConsumerStatefulWidget {
  const SsYourIpCard({super.key});

  @override
  ConsumerState<SsYourIpCard> createState() => _SsYourIpCardState();
}

class _SsYourIpCardState extends ConsumerState<SsYourIpCard> {
  late final OutboundIpProbe _probe;

  @override
  void initState() {
    super.initState();
    _probe = ref.read(outboundIpProbeProvider.notifier)..watch(routedOutbound);
  }

  @override
  void dispose() {
    _probe.unwatch(routedOutbound);
    super.dispose();
  }

  void _refresh(String? ip) {
    _probe.refresh([routedOutbound]);
    if (ip != null && ref.read(ipQualityProvider(ip)).hasError) {
      ref.invalidate(ipQualityProvider(ip));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final entry = ref.watch(
      outboundIpProbeProvider.select((state) => state.entryOf(routedOutbound)),
    );
    final info = entry.value;
    final loading =
        entry.phase == ProbePhase.probing ||
        (entry.phase == ProbePhase.empty && info == null);
    final failed = entry.phase == ProbePhase.failed && info == null;
    final quality = info == null ? null : ref.watch(ipQualityProvider(info.ip));
    final organization = switch (quality?.value) {
      IpQuality(organization: final name?) when name.isNotEmpty => name,
      IpQuality(asn: final asn?) => 'AS$asn',
      _ => null,
    };
    return SsCard(
      onTap: info == null
          ? null
          : () => showIpQualitySheet(context, ip: info.ip),
      semanticLabel: l.ssYourIp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SsOverline(
            l.ssYourIp,
            trailing: SsIconButton(
              icon: LucideIcons.refreshCw,
              tooltip: l.retry,
              size: 32,
              busy: loading,
              onTap: () => _refresh(info?.ip),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (info != null) ...[
                SsCountryFlag(code: info.countryCode, size: 26),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AnimatedSwitcher(
                  duration: SsMotion.of(context, SsMotion.medium),
                  child: Text(
                    info?.ip ?? (failed ? l.ssIpUnavailable : '···'),
                    key: ValueKey(info?.ip ?? failed),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SsType.monoLarge.style.copyWith(
                      fontSize: 20,
                      color: failed ? palette.rose : palette.text,
                    ),
                  ),
                ),
              ),
              if (info != null)
                SsBadge(
                  label: info.countryCode.toUpperCase(),
                  color: palette.sky,
                ),
            ],
          ),
          if (organization != null) ...[
            const SizedBox(height: 6),
            Text(
              organization,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsType.caption.color(palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
