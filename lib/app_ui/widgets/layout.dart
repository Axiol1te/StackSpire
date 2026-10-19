import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The widest a column of StackSpire content grows; wider windows (tablets,
/// landscape phones) centre it.
const ssContentMaxWidth = 560.0;

/// Side padding that keeps content [ssContentMaxWidth] wide and centred.
double ssSidePadding(BuildContext context, [double min = 20]) {
  final width = MediaQuery.sizeOf(context).width;
  return math.max(min, (width - ssContentMaxWidth) / 2);
}
