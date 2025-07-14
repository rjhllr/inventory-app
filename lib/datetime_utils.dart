import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

/// Utility class for locale-specific datetime formatting
class DateTimeUtils {
  /// Format date for display based on locale
  /// German: dd.MM.yyyy
  /// US: MM/dd/yyyy
  static String formatDate(BuildContext context, DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('dd.MM.yyyy').format(date);
    } else {
      return DateFormat('MM/dd/yyyy').format(date);
    }
  }

  /// Format time for display based on locale
  /// German: HH:mm
  /// US: h:mm a
  static String formatTime(BuildContext context, DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('h:mm a').format(date);
    }
  }

  /// Format datetime for display based on locale
  /// German: dd.MM.yyyy HH:mm
  /// US: MM/dd/yyyy h:mm a
  static String formatDateTime(BuildContext context, DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } else {
      return DateFormat('MM/dd/yyyy h:mm a').format(date);
    }
  }

  /// Format full datetime with seconds for display based on locale
  /// German: dd.MM.yyyy HH:mm:ss
  /// US: MM/dd/yyyy h:mm:ss a
  static String formatFullDateTime(BuildContext context, DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('dd.MM.yyyy HH:mm:ss').format(date);
    } else {
      return DateFormat('MM/dd/yyyy h:mm:ss a').format(date);
    }
  }

  /// Format datetime for product database "last updated" based on locale
  /// German: dd.MM.yyyy HH:mm:ss
  /// US: M/d/yyyy h:mm:ss a
  static String formatLastUpdated(BuildContext context, DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('dd.MM.yyyy HH:mm:ss').format(date);
    } else {
      return DateFormat('M/d/yyyy h:mm:ss a').format(date);
    }
  }

  /// Format datetime for transaction history based on locale
  /// German: dd.MM.yyyy HH:mm
  /// US: MMM d, yyyy h:mm a
  static String formatTransactionHistory(BuildContext context, DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    if (locale == 'de') {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    }
  }

  /// Format datetime for scan results page (time only as requested)
  /// German: HH:mm
  /// US: h:mm a
  static String formatScanTime(BuildContext context, DateTime date) {
    return formatTime(context, date);
  }

  /// Check if the given date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isAtSameMomentAs(today);
  }

  /// Format datetime for "today at" display based on locale
  /// Uses existing localization strings with time placeholder
  static String formatTodayAt(BuildContext context, DateTime date) {
    final timeFormat = formatTime(context, date);
    return AppLocalizations.of(context)!.todayAt(timeFormat);
  }
} 