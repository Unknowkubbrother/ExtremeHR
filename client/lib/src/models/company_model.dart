class CompanyModel {
  final int? id;
  final String name;
  final String location;
  final int userId;

  CompanyModel({
    this.id,
    required this.name,
    required this.location,
    required this.userId,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'location': location};
  }
}
