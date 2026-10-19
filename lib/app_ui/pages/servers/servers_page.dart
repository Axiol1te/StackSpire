import 'package:fl_clash/app_ui/flows/add_profile.dart';
import 'package:fl_clash/app_ui/pages/servers/group_section.dart';
import 'package:fl_clash/app_ui/pages/servers/server_choices.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/app_ui/pages/servers/profile_card.dart';
import 'package:fl_clash/app_ui/pages/servers/servers_menu.dart';
import 'package:fl_clash/app_ui/shell/shell.dart';
import 'package:fl_clash/app_ui/theme/palette.dart';
import 'package:fl_clash/app_ui/theme/type.dart';
import 'package:fl_clash/app_ui/widgets/layout.dart';
import 'package:fl_clash/app_ui/widgets/buttons.dart';
import 'package:fl_clash/app_ui/widgets/reveal.dart';
import 'package:fl_clash/app_ui/widgets/search.dart';
import 'package:fl_clash/app_ui/widgets/states.dart';
import 'package:fl_clash/app_ui/widgets/text.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class SsServersPage extends ConsumerWidget {
  const SsServersPage({super.key});

  Future<void> _updateAll(WidgetRef ref) async {
    await globalState.safeRun(
      () => ref.read(profilesActionProvider.notifier).updateProfiles(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final palette = context.ss;
    final top = MediaQuery.paddingOf(context).top;
    final side = ssSidePadding(context);
    final bottom = SsShellInsets.bottomOf(context);
    final profiles = ref.watch(profilesProvider);
    final currentId = ref.watch(currentProfileIdProvider);
    final query = ref.watch(queryProvider(QueryTag.proxies));
    final appliedId = ref.watch(appliedProfileIdProvider);
    final profile = ref.watch(currentProfileProvider);
    final allGroups = ref.watch(groupsProvider);
    final hideTimeout = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.hideTimeoutProxies),
    );
    final groups = hideTimeout
        ? computeHideTimeout(
            groups: allGroups,
            allGroups: allGroups,
            delayMap: ref.watch(delaysAtLastTestBatchProvider),
            selectedMap: ref.watch(selectedMapProvider),
            defaultTestUrl: ref.watch(realTestUrlProvider()),
          )
        : allGroups;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final ready = currentId != null && currentId == appliedId;
    final choices = ready
        ? subscriptionServerChoices(
                groups,
                mode: mode,
                preferredGroup: profile?.currentGroupName,
              )
              .where(
                (choice) =>
                    SearchQuery(query).matches(choice.proxy.searchFields),
              )
              .toList()
        : const <SsServerChoice>[];
    final hasRemote = profiles.any(
      (profile) => profile.type == ProfileType.url,
    );
    return RefreshIndicator(
      color: palette.accent,
      backgroundColor: palette.raised,
      edgeOffset: top,
      onRefresh: hasRemote ? () => _updateAll(ref) : () async {},
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(side, top + 16, side, 0),
            sliver: SliverList.list(
              children: [
                SsReveal(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: SsHeadline([
                          SsRun(l.ssServersLead),
                          SsRun.accent(l.ssServersAccent, color: palette.sky),
                        ], type: SsType.title),
                      ),
                      SsIconButton(
                        icon: LucideIcons.plus,
                        tooltip: l.ssAddSubscription,
                        onTap: () => showSsAddProfileSheet(context),
                      ),
                      SsIconButton(
                        icon: LucideIcons.ellipsis,
                        tooltip: l.more,
                        onTap: () => showServersMenu(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SsReveal(
                  index: 1,
                  child: SsOverline(
                    l.ssSubscriptions,
                    trailing: hasRemote
                        ? SsUpdateAllButton(onTap: () => _updateAll(ref))
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                if (profiles.isEmpty)
                  SsReveal(
                    index: 2,
                    child: SsStateView(
                      icon: LucideIcons.inbox,
                      title: l.ssEmptyTitleLead + l.ssEmptyTitleAccent,
                      message: l.ssEmptyMessage,
                      actionLabel: l.ssAddSubscription,
                      actionIcon: LucideIcons.plus,
                      onAction: () => showSsAddProfileSheet(context),
                    ),
                  ),
              ],
            ),
          ),
          if (profiles.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: side),
              sliver: SliverList.separated(
                itemCount: profiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => SsReveal(
                  key: ValueKey(profiles[index].id),
                  index: index + 2,
                  child: SsProfileCard(
                    profile: profiles[index],
                    selected: profiles[index].id == currentId,
                  ),
                ),
              ),
            ),
          if (profiles.isNotEmpty) ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 28, side, 10),
              sliver: SliverToBoxAdapter(child: SsOverline(l.ssServers)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 12),
              sliver: const SliverToBoxAdapter(child: SsProxySearchField()),
            ),
            if (mode == Mode.direct)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverToBoxAdapter(
                  child: SsStateView(
                    icon: LucideIcons.arrowRight,
                    color: palette.mint,
                    title: l.ssDirectNoProxy,
                    message: l.ssDirectModeHint,
                  ),
                ),
              )
            else if (!ready)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverToBoxAdapter(
                  child: SsStateView(
                    icon: LucideIcons.refreshCw,
                    title: l.loading,
                  ),
                ),
              )
            else if (choices.isEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverToBoxAdapter(
                  child: SsStateView(
                    icon: LucideIcons.searchX,
                    title: query.isEmpty
                        ? l.nullTip(l.proxies)
                        : l.ssNothingFound,
                    message: query.isEmpty ? l.ssGroupsAppearHint : null,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverList.separated(
                  itemCount: choices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => SsReveal(
                    key: ValueKey('$currentId-${choices[index].proxy.name}'),
                    index: index.clamp(0, 4),
                    offset: 10,
                    child: _ServerChoiceTile(choice: choices[index]),
                  ),
                ),
              ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }
}

class _ServerChoiceTile extends ConsumerWidget {
  const _ServerChoiceTile({required this.choice});

  final SsServerChoice choice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = [
      for (final pick in choice.selections.entries)
        ref.watch(selectedProxyNameProvider(pick.key)) == pick.value,
    ].every((value) => value);
    return SsNodeTile(
      group: choice.group,
      proxy: choice.proxy,
      inUse: selected,
      onTap: () {
        final actions = ref.read(proxiesActionProvider.notifier);
        for (final pick in choice.selections.entries.toList().reversed) {
          actions.changeProxyDebounce(pick.key, pick.value);
        }
      },
    );
  }
}
