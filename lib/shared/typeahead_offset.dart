import 'package:flutter/widgets.dart';

/// Offset for a [TypeAheadField] suggestions box that keeps it lined up with
/// the text field.
///
/// flutter_typeahead centers the suggestions box under the field and then
/// pads it by the screen's left and right safe-area insets. When those insets
/// differ (e.g. a notch or status bar on one side of the screen), the box
/// is pushed sideways by half the difference, which can move it off the edge
/// of the screen. This returns an offset that cancels that shift.
Offset typeaheadSuggestionsOffset(BuildContext context) {
  // Register a dependency on the local MediaQuery so the offset updates
  // when the screen rotates or the insets change.
  MediaQuery.maybeOf(context);
  final overlay = Overlay.maybeOf(context);
  final mediaQuery = MediaQuery.maybeOf(overlay?.context ?? context);
  if (mediaQuery == null) {
    return const Offset(0, 5);
  }
  final insets = mediaQuery.padding + mediaQuery.viewInsets;
  return Offset((insets.right - insets.left) / 2, 5);
}
