import 'dart:convert';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SubscriptionMetadata parse(
    Map<String, List<String>> headers, {
    String content = '',
    String url = 'https://example.com/sub#Fallback',
  }) =>
      SubscriptionMetadata.parse(headers: headers, content: content, url: url);

  test(
    'Remnawave title wins over username without renaming internal references',
    () {
      final metadata = parse({
        'Profile-Title': ['base64:${base64.encode(utf8.encode('🚀 Мой VPN'))}'],
        'Content-Disposition': ['attachment; filename=user_123456'],
        'Subscription-Userinfo': [
          'upload=0; download=53687091200; total=107374182400; expire=1800000000',
        ],
        'support-url': ['https://t.me/support'],
        'profile-web-page-url': ['https://example.com/account'],
        'subscription-refill-date': ['1799000000'],
      });
      const profile = Profile(
        id: 1,
        type: ProfileType.url,
        label: 'user_123456',
        url: 'https://example.com/sub',
        autoUpdateDuration: defaultUpdateDuration,
      );
      final updated = profile.withSubscriptionMetadata(metadata);
      expect(updated.displayLabel, '🚀 Мой VPN');
      expect(updated.realLabel, 'user_123456');
      expect(updated.subscriptionInfo?.usage, 0.5);
      expect(updated.supportUrl, 'https://t.me/support');
      expect(updated.subscriptionRefillDate, 1799000000);
      expect(
        Profile.fromJson(
          jsonDecode(jsonEncode(updated)) as Map<String, Object?>,
        ),
        updated,
      );
    },
  );

  test('explicit and legacy manual names survive remote title changes', () {
    final metadata = parse({
      'profile-title': ['Provider'],
      'content-disposition': ['attachment; filename=user_123456'],
    });
    final profile = Profile.normal(
      label: 'Family',
      url: 'https://example.com/sub',
    );
    expect(profile.withSubscriptionMetadata(metadata).displayLabel, 'Family');
    final legacy = profile.copyWith(hasCustomLabel: false);
    expect(legacy.withSubscriptionMetadata(metadata).displayLabel, 'Family');
  });

  test('HTTP metadata overrides comments, malformed title falls back safely', () {
    expect(
      parse({
        'profile-title': ['Header'],
      }, content: '#profile-title: Comment').title,
      'Header',
    );
    final metadata = parse({
      'profile-title': ['base64:%%%'],
      'content-disposition': [
        "attachment; filename*=UTF-8''%D0%92%D0%9F%D0%9D.yaml",
      ],
    });
    expect(metadata.title, 'ВПН.yaml');
    expect(
      parse(
        {},
        content:
            '#profile-title: Комментарий\n#support-url: https://example.com/help',
      ).title,
      'Комментарий',
    );
    expect(parse({}).title, 'Fallback');
    expect(parse({}, url: 'https://example.com/config.yaml').title, 'config');
  });

  test('absent and invalid quota never become unlimited', () {
    expect(parse({}).info, isNull);
    final unknown = parse({
      'subscription-userinfo': ['upload=0; download=10; total=bad'],
    }).info!;
    expect(unknown.hasUsage, isTrue);
    expect(unknown.hasTotal, isFalse);
    expect(unknown.usage, isNull);
    final unlimited = parse({
      'subscription-userinfo': ['upload=0; download=10; total=0; expire=0'],
    }).info!;
    expect(unlimited.hasTotal, isTrue);
    expect(unlimited.total, 0);
    expect(unlimited.expireDate, isNull);
    expect(unlimited.usage, isNull);
  });

  test('invalid optional fields do not break a usable subscription', () {
    final metadata = parse({
      'profile-title': ['Working'],
      'content-disposition': ["attachment; filename*=UTF-8''%ZZ"],
      'support-url': ['javascript:alert(1)'],
      'profile-web-page-url': ['file:///private'],
      'subscription-refill-date': ['999999999999999999'],
      'subscription-userinfo': ['upload=-1; download=10; total=100'],
    });
    expect(metadata.title, 'Working');
    expect(metadata.supportUrl, isNull);
    expect(metadata.webPageUrl, isNull);
    expect(metadata.refillDate, isNull);
    expect(metadata.info?.upload, 0);
  });
}
