class BookingModel {
  final int id;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String status;

  BookingModel({
    required this.id,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      bookingDate: json['bookingDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}