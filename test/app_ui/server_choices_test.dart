import 'package:fl_clash/app_ui/pages/servers/server_choices.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nl = Proxy(name: 'NL', type: 'Mieru');
  const de = Proxy(name: 'DE', type: 'VLESS');
  const groups = [
    Group(
      name: 'proxy',
      type: GroupType.Selector,
      hidden: false,
      all: [
        Proxy(name: 'manual', type: 'Selector'),
        Proxy(name: 'auto', type: 'URLTest'),
        nl,
        Proxy(name: 'DIRECT', type: 'Direct'),
        Proxy(name: 'REJECT', type: 'Reject'),
      ],
    ),
    Group(
      name: 'manual',
      type: GroupType.Selector,
      hidden: true,
      all: [
        nl,
        de,
        Proxy(name: 'proxy', type: 'Selector'),
      ],
    ),
    Group(name: 'auto', type: GroupType.URLTest, hidden: true, all: [nl, de]),
    Group(
      name: 'Streaming',
      type: GroupType.Selector,
      hidden: false,
      all: [Proxy(name: 'US', type: 'Trojan')],
    ),
    Group(
      name: 'GLOBAL',
      type: GroupType.Selector,
      hidden: true,
      all: [
        Proxy(name: 'proxy', type: 'Selector'),
        Proxy(name: 'DIRECT', type: 'Direct'),
      ],
    ),
  ];

  test(
    'flattens reachable servers, keeps auto, deduplicates, and stops cycles',
    () {
      final choices = subscriptionServerChoices(groups, mode: Mode.rule);
      expect(choices.map((choice) => choice.proxy.name), ['auto', 'NL', 'DE']);
      expect(
        choices.singleWhere((choice) => choice.proxy.name == 'NL').selections,
        {'proxy': 'NL'},
      );
      expect(
        choices.singleWhere((choice) => choice.proxy.name == 'DE').selections,
        {'proxy': 'manual', 'manual': 'DE'},
      );
    },
  );

  test('global choices retain the GLOBAL routing hop', () {
    final choices = subscriptionServerChoices(groups, mode: Mode.global);
    expect(
      choices.singleWhere((choice) => choice.proxy.name == 'NL').selections,
      {'GLOBAL': 'proxy', 'proxy': 'NL'},
    );
  });

  test('honors the selected routing group and Direct mode', () {
    expect(
      subscriptionServerChoices(
        groups,
        mode: Mode.rule,
        preferredGroup: 'Streaming',
      ).single.proxy.name,
      'US',
    );
    expect(subscriptionServerChoices(groups, mode: Mode.direct), isEmpty);
    expect(subscriptionServerChoices([], mode: Mode.rule), isEmpty);
  });
}
