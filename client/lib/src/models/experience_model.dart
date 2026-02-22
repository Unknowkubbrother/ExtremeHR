class Experience {
  final String company;
  final String role;
  final int? startYear;
  final int? startMonth;
  final int? endYear;
  final int? endMonth;
  final String description;

  Experience({
    required this.company,
    required this.role,
    this.startYear,
    this.startMonth,
    this.endYear,
    this.endMonth,
    required this.description,
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
}
