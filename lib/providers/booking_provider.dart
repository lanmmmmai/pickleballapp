import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final List<BookingModel> bookings = [];

  void setBookings(List<BookingModel> values) {
    bookings
      ..clear()
      ..addAll(values);
    notifyListeners();
  }
}