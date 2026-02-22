class Experience {
  final String company;
  final String role;
  final String startDate;
  final String endDate;
  final String description;

  Experience({
    required this.company,
    required this.role,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  Experience copyWith({
    String? company,
    String? role,
    String? startDate,
    String? endDate,
    String? description,
  }) {
    return Experience(
      company: company ?? this.company,
      role: role ?? this.role,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
    );
  }
}
