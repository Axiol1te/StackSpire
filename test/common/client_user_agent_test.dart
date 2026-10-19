import 'dart:io';

import 'package:fl_clash/common/package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('subscription user agent identifies the bundled core capabilities', () {
    final info = PackageInfo(
      appName: 'StackSpire',
      packageName: 'com.stackspire.vpn',
      version: '0.9.1',
      buildNumber: '2026101805',
    );
    expect(info.ua, contains('StackSpire/v0.9.1'));
    expect(info.ua, contains('ClashMeta/$bundledMihomoVersion'));
    expect(info.ua, contains('mihomo/$bundledMihomoVersion'));
  });

  test('Windows metadata cannot select a legacy Clash subscription format', () {
    final info = PackageInfo(
      appName: 'clash',
      packageName: 'com.follow.clash',
      version: '0.9.1',
      buildNumber: '2026101806',
    );
    expect(info.ua, startsWith('ClashMeta/$bundledMihomoVersion '));
    expect(info.ua, contains('clash/v0.9.1'));
  });

  test('advertised core version matches the native build', () {
    final config =
        loadYaml(File('build_config.yaml').readAsStringSync()) as YamlMap;
    expect(config['core_version'], 'v$bundledMihomoVersion');
  });
}
