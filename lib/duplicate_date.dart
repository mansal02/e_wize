import 'package:flutter/material.dart';


class DuplicateDate {
  
  static bool isDuplicateDate(DateTime selectedDate, List<DateTime> bookedDates) {
    return bookedDates.any((date) =>
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day);
  }

  static bool isTimeOverlap(TimeOfDay start, TimeOfDay end, TimeOfDay existingStart, TimeOfDay existingEnd) {
    double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;
    
    return toDouble(start) < toDouble(existingEnd) && toDouble(end) > toDouble(existingStart);
  }
}