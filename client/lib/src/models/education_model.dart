class Education {
  final String institution;
  final String degree;
  final String faculty;
  final String major;
  final String gpax;
  final String startDate;
  final String endDate;

  Education({
    required this.institution,
    required this.degree,
    required this.faculty,
    required this.major,
    required this.gpax,
    required this.startDate,
    required this.endDate,
  });

  Education copyWith({
    String? institution,
    String? degree,
    String? faculty,
    String? major,
    String? gpax,
    String? startDate,
    String? endDate,
  }) {
    return Education(
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      gpax: gpax ?? this.gpax,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
