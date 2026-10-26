import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `6 Oct 2026`
String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// `6 Oct 2026, 11:28 pm`
String formatDayTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '${formatDay(d)}, $hour12:$minute ${d.hour < 12 ? 'am' : 'pm'}';
}

String formatMoney(double value) => '₹${value.toStringAsFixed(2)}';

/// Placed is the normal state; anything else (cancelled, …) reads as a warning.
Color statusColor(String status) => switch (status) {
  'placed' || 'completed' || 'delivered' => AppColors.successText,
  'pending' || 'processing' || 'shipped' => AppColors.infoText,
  'cancelled' || 'refunded' || 'failed' => AppColors.errorText,
  _ => AppColors.secondaryText,
};
