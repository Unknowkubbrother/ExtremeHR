class JobDetail {
  final String title;
  final String company;
  final String location;

  final String description;
  final List<String> responsibilities;
  final List<String> qualifications;
  final List<String> skills;

  final int headcount;
  final int minAge;
  final int maxAge;
  final int minSalary;
  final int maxSalary;

  final DateTime postedAt;

  JobDetail({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.responsibilities,
    required this.qualifications,
    required this.skills,
    required this.headcount,
    required this.minAge,
    required this.maxAge,
    required this.minSalary,
    required this.maxSalary,
    required this.postedAt,
  });

  JobDetail copyWith({
    String? title,
    String? company,
    String? location,
    String? description,
    List<String>? responsibilities,
    List<String>? qualifications,
    List<String>? skills,
    int? headcount,
    int? minAge,
    int? maxAge,
    int? minSalary,
    int? maxSalary,
    DateTime? postedAt,
  }) {
    return JobDetail(
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      description: description ?? this.description,
      responsibilities: responsibilities ?? this.responsibilities,
      qualifications: qualifications ?? this.qualifications,
      skills: skills ?? this.skills,
      headcount: headcount ?? this.headcount,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      postedAt: postedAt ?? this.postedAt,
    );
  }
}
