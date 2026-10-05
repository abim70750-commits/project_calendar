import 'package:intl/intl.dart';

/// Strips the time part so comparisons are day-based.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days from today to the deadline. Uses UTC midnights so a DST shift
/// on the device can never produce an off-by-one.
int daysLeftFor(DateTime deadline, [DateTime? now]) {
  final a = DateTime.utc(deadline.year, deadline.month, deadline.day);
  final n = now ?? DateTime.now();
  final b = DateTime.utc(n.year, n.month, n.day);
  return a.difference(b).inDays;
}

String formatDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
