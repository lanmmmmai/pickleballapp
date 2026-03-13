import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingTile extends StatelessWidget {
  final BookingModel booking;

  const BookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${booking.bookingDate} ${booking.startTime} - ${booking.endTime}'),
        subtitle: Text('Trang thai: ${booking.status}'),
        trailing: Text('${booking.totalPrice.toStringAsFixed(0)} VND'),
      ),
    );
  }
}