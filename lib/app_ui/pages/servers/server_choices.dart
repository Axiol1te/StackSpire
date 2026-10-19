import 'dart:collection';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

class SsServerChoice {
  const SsServerChoice({
    required this.proxy,
    required this.group,
    required this.selections,
  });

  final Proxy proxy;
  final Group group;
  final Map<String, String> selections;
}

List<SsServerChoice> subscriptionServerChoices(
  List<Group> groups, {
  required Mode mode,
  String? preferredGroup,
}) {
  if (mode == Mode.direct || groups.isEmpty) return const [];
  final byName = {for (final group in groups) group.name: group};
  final visible = groups.where(
    (group) => mode == Mode.global || group.hidden == false,
  );
  final root = mode == Mode.global
      ? byName['GLOBAL'] ?? visible.firstOrNull
      : visible.where((group) => group.name == preferredGroup).firstOrNull ??
            visible.where((group) => group.name != 'GLOBAL').firstOrNull;
  if (root == null) return const [];
  final queue = Queue<(Group, Map<String, String>)>()..add((root, const {}));
  final visited = <String>{};
  final choices = <String, SsServerChoice>{};
  while (queue.isNotEmpty) {
    final (group, path) = queue.removeFirst();
    if (!visited.add(group.name)) continue;
    if (group.type != GroupType.Selector && !group.type.isComputedSelected) {
      continue;
    }
    for (final proxy in group.all) {
      final picks = {...path, group.name: proxy.name};
      final nested = byName[proxy.name];
      if (nested != null) {
        if (nested.type.isComputedSelected) {
          choices.putIfAbsent(
            proxy.name,
            () => SsServerChoice(proxy: proxy, group: group, selections: picks),
          );
        }
        queue.add((nested, picks));
      } else if (!const {
            'direct',
            'reject',
            'rejectdrop',
            'pass',
            'compatible',
            'dns',
          }.contains(proxy.type.toLowerCase()) &&
          !const {
            'DIRECT',
            'REJECT',
            'REJECT-DROP',
            'PASS',
            'COMPATIBLE',
          }.contains(proxy.name)) {
        choices.putIfAbsent(
          proxy.name,
          () => SsServerChoice(proxy: proxy, group: group, selections: picks),
        );
      }
    }
  }
  return choices.values.toList();
}
