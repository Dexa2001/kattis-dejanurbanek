import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateFormatters {
  static String testDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');

    if (parsed != null) {
      return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
    }

    if (value is Timestamp) {
      return DateFormat('MMM d, yyyy • h:mm a').format(value.toDate());
    }

    return 'Unknown date';
  }
}
