class Education {
  final String institution;
  final String degree;
  final String faculty;
  final String major;
  final String gpax;
  final int? startYear;
  final int? startMonth;
  final int? endYear;
  final int? endMonth;

  Education({
    required this.institution,
    required this.degree,
    required this.faculty,
    required this.major,
    required this.gpax,
    this.startYear,
    this.startMonth,
    this.endYear,
    this.endMonth,
  });

  Education copyWith({
    String? institution,
    String? degree,
    String? faculty,
    String? major,
    String? gpax,
    int? startYear,
    int? startMonth,
    int? endYear,
    int? endMonth,
  }) {
    return Education(
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      gpax: gpax ?? this.gpax,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      endYear: endYear ?? this.endYear,
      endMonth: endMonth ?? this.endMonth,
    );
  }
}
