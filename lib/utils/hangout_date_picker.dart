import 'package:flutter/material.dart';
import 'package:friend_builder/utils/local_date.dart';

/// Shows a date picker and returns the picked calendar day combined with
/// [selectedDate]'s clock time, or null if cancelled / same day.
Future<DateTime?> pickHangoutDate({
  required BuildContext context,
  required DateTime selectedDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: firstDate ?? DateTime(2018, 8),
        lastDate: lastDate ?? DateTime.now(),
      ) ??
      selectedDate;
  if (isSameHangoutDate(picked, selectedDate)) {
    return null;
  }
  return combineHangoutDateAndTime(picked, selectedDate);
}
