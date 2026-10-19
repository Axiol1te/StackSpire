import 'dart:convert';

import 'package:fl_clash/common/request.dart' show getFileNameForDisposition;
import 'package:fl_clash/models/profile.dart';

class SubscriptionMetadata {
  const SubscriptionMetadata({
    this.title,
    this.fileName,
    this.info,
    this.supportUrl,
    this.webPageUrl,
    this.refillDate,
  });

  final String? title;
  final String? fileName;
  final SubscriptionInfo? info;
  final String? supportUrl;
  final String? webPageUrl;
  final int? refillDate;

  factory SubscriptionMetadata.parse({
    required Map<String, List<String>> headers,
    required String content,
    required String url,
  }) {
    final values = <String, String>{};
    for (final line in const LineSplitter().convert(content).take(10)) {
      final match = RegExp(r'^\s*(?:#|//)\s*([^:]+):\s*(.*)$').firstMatch(line);
      if (match != null) {
        values[match[1]!.trim().toLowerCase()] = match[2]!.trim();
      }
    }
    for (final entry in headers.entries) {
      if (entry.value.isNotEmpty) {
        values[entry.key.toLowerCase()] = entry.value.first.trim();
      }
    }
    String? fileName;
    try {
      fileName = getFileNameForDisposition(values['content-disposition']);
    } on FormatException {
      fileName = null;
    } on ArgumentError {
      fileName = null;
    }
    final uri = Uri.tryParse(url);
    final fallback = uri?.pathSegments.lastOrNull;
    final title =
        [
              _text(values['profile-title']),
              fileName,
              uri?.fragment,
              fallback?.replaceFirst(
                RegExp(r'\.(yaml|yml|json|txt)$', caseSensitive: false),
                '',
              ),
            ]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .firstOrNull;
    final refill = int.tryParse(values['subscription-refill-date'] ?? '');
    final userinfo = values['subscription-userinfo'];
    return SubscriptionMetadata(
      title: title,
      fileName: fileName,
      info: userinfo == null || userinfo.isEmpty
          ? null
          : SubscriptionInfo.formHString(userinfo),
      supportUrl: _webUrl(values['support-url']),
      webPageUrl: _webUrl(values['profile-web-page-url']),
      refillDate: refill != null && refill > 0 && refill <= 8640000000000
          ? refill
          : null,
    );
  }

  static String? _text(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('base64:')) return value;
    try {
      return utf8.decode(base64.decode(base64.normalize(value.substring(7))));
    } on FormatException {
      return null;
    }
  }

  static String? _webUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty
        ? value
        : null;
  }
}
