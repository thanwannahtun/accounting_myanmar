import 'package:intl/intl.dart';

extension StringExtension on String {
  String formatNumber({String? currency}) {
    return NumberFormat('#,###').format(int.parse(this)) + (currency ?? "");
  }
}

// Helper Extension to parse Duration from a String (e.g., "0:10:00.000000")
extension DurationParser on String {
  Duration toDuration() {
    List<String> parts = split(':');
    if (parts.length == 3) {
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2].split('.')[0]),
      );
    }
    return Duration.zero; // Default or error case
  }
}

// Returns "05:25" from a Duration "05:25:00.000000"
extension DurationToReadableString on Duration {
  String toReadableString() {
    // Get total hours and pad with a leading zero if less than 10
    String hours = inHours.toString().padLeft(2, '0');

    // Get the remaining minutes (0-59) and pad with a leading zero
    String minutes = (inMinutes % 60).toString().padLeft(2, '0');

    return "$hours:$minutes";
  }
}

extension NumberFormatDoubleExt on double? {
  String get toCurrency => NumberFormat("#,##0", "en_US").format(this ?? 0);
}

extension NumberFormatIntExt on int? {
  String get toCurrency => NumberFormat("#,##0", "en_US").format(this ?? 0);
}
