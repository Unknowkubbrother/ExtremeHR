class Education {
  final String institution;
  final String? degree;
  final String? faculty;
  final String? major;
  final double? gpax;
  final int? startYear;
  final int? startMonth;
  final int? endYear;
  final int? endMonth;

  Education({
    required this.institution,
    this.degree,
    this.faculty,
    this.major,
    this.gpax,
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
    double? gpax,
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

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'faculty': faculty,
      'major': major,
      'gpax': gpax,
      'start_year': startYear,
      'start_month': startMonth,
      'end_year': endYear,
      'end_month': endMonth,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] ?? '',
      degree: json['degree'],
      faculty: json['faculty'],
      major: json['major'],
      gpax: (json['gpax'] as num?)?.toDouble(),
      startYear: json['start_year'],
      startMonth: json['start_month'],
      endYear: json['end_year'],
      endMonth: json['end_month'],
    );
  }
}
