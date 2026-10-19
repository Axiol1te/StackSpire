import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenses = {
  'Manrope': 'assets/ss_fonts/licenses/OFL-manrope.txt',
  'Montserrat': 'assets/ss_fonts/licenses/OFL-montserrat.txt',
  'JetBrains Mono': 'assets/ss_fonts/licenses/OFL-jetbrainsmono.txt',
};

var _registered = false;

/// Lists the bundled fonts' SIL Open Font Licenses on the licenses page.
void registerSsLicenses() {
  if (_registered) {
    return;
  }
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: path) in _fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(path));
    }
  });
}
