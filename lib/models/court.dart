class CourtModel {
  final int id;
  final String name;
  final double price;

  CourtModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}