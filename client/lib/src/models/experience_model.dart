class Experience {
  final String company;
  final String? role;
  final int? startYear;
  final int? startMonth;
  final int? endYear;
  final int? endMonth;
  final String? description;

  Experience({
    required this.company,
    this.role,
    this.startYear,
    this.startMonth,
    this.endYear,
    this.endMonth,
    this.description,
  });

  Experience copyWith({
    String? company,
    String? role,
    int? startYear,
    int? startMonth,
    int? endYear,
    int? endMonth,
    String? description,
  }) {
    return Experience(
      company: company ?? this.company,
      role: role ?? this.role,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      endYear: endYear ?? this.endYear,
      endMonth: endMonth ?? this.endMonth,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'role': role,
      'start_year': startYear,
      'start_month': startMonth,
      'end_year': endYear,
      'end_month': endMonth,
      'description': description,
    };
  }

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      company: json['company'] ?? '',
      role: json['role'],
      startYear: json['start_year'],
      startMonth: json['start_month'],
      endYear: json['end_year'],
      endMonth: json['end_month'],
      description: json['description'],
    );
  }
}
