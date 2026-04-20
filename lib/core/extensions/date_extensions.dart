import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

extension DateExtension on DateTime {
  /// Indian financial year string: "FY2526" for April 2025 – March 2026
  String get financialYearKey {
    final fy = month >= AppConstants.fyStartMonth ? year : year - 1;
    return 'FY${fy.toString().substring(2)}${(fy + 1).toString().substring(2)}';
  }

  /// Financial year start date: April 1
  DateTime get fyStart {
    final fy = month >= AppConstants.fyStartMonth ? year : year - 1;
    return DateTime(fy, AppConstants.fyStartMonth, AppConstants.fyStartDay);
  }

  /// Financial year end date: March 31
  DateTime get fyEnd {
    final fy = month >= AppConstants.fyStartMonth ? year : year - 1;
    return DateTime(fy + 1, 3, 31);
  }

  /// Holding days from this date to today
  int get holdingDaysToNow => DateTime.now().difference(this).inDays;

  /// Is this holding LTCG for equity (> 365 days)?
  bool get isEquityLtcg => holdingDaysToNow > AppConstants.equityLtcgHoldingDays;

  /// Format for display: "15 Jan 2024"
  String get displayDate => DateFormat(AppConstants.displayDateFormat).format(this);

  /// Format for DB / API: "2024-01-15"
  String get isoDate => DateFormat('yyyy-MM-dd').format(this);

  /// Format for transaction import: "15-01-2024"
  String get navDate => DateFormat(AppConstants.navDateFormat).format(this);

  /// Short month: "Jan 2024"
  String get monthYear => DateFormat(AppConstants.displayMonthYearFormat).format(this);

  /// Days until a future date (negative if past)
  int daysUntil(DateTime other) => other.difference(this).inDays;

  /// Is same calendar date
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension NullableDateExtension on DateTime? {
  String get displayDateOrDash {
    if (this == null) return '—';
    return this!.displayDate;
  }

  String get daysRemainingLabel {
    if (this == null) return '—';
    final days = DateTime.now().daysUntil(this!);
    if (days < 0) return 'Matured';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day';
    if (days < 30) return '$days days';
    if (days < 365) {
      final months = (days / 30).round();
      return '$months month${months > 1 ? 's' : ''}';
    }
    final years = (days / 365).toStringAsFixed(1);
    return '$years years';
  }
}
