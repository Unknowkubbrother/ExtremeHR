class JobDetail {
  final int id;
  final String title;
  final List<String> jobFields;
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
    required this.id,
    required this.title,
    required this.jobFields,
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
    int? id,
    String? title,
    List<String>? jobFields,
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
      id: id ?? this.id,
      title: title ?? this.title,
      jobFields: jobFields ?? this.jobFields,
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

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      jobFields: List<String>.from(json['job_fields'] ?? []),
      company: json['company'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      qualifications: List<String>.from(json['qualifications'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      headcount: json['headcount'] ?? 0,
      minAge: json['minAge'] ?? 0,
      maxAge: json['maxAge'] ?? 0,
      minSalary: json['minSalary'] ?? 0,
      maxSalary: json['maxSalary'] ?? 0,
      postedAt: json['postedAt'] != null
          ? DateTime.parse(json['postedAt'])
          : DateTime.now(),
    );
  }
}
