class JobUpdate {
  final int id;
  final String? title;
  final List<String>? jobFields;
  final String? description;
  final List<String>? responsibilities;
  final List<String>? qualifications;
  final List<String>? skills;
  final int? headcount;
  final int? minAge;
  final int? maxAge;
  final int? minSalary;
  final int? maxSalary;

  JobUpdate({
    required this.id,
    this.title,
    this.jobFields,
    this.description,
    this.responsibilities,
    this.qualifications,
    this.skills,
    this.headcount,
    this.minAge,
    this.maxAge,
    this.minSalary,
    this.maxSalary,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'id': id};
    if (title != null) data['title'] = title;
    if (jobFields != null) data['job_fields'] = jobFields;
    if (description != null) data['description'] = description;
    if (responsibilities != null) data['responsibilities'] = responsibilities;
    if (qualifications != null) data['qualifications'] = qualifications;
    if (skills != null) data['skills'] = skills;
    if (headcount != null) data['headcount'] = headcount;
    if (minAge != null) data['minAge'] = minAge;
    if (maxAge != null) data['maxAge'] = maxAge;
    if (minSalary != null) data['minSalary'] = minSalary;
    if (maxSalary != null) data['maxSalary'] = maxSalary;
    return data;
  }
}

class JobCreate {
  final String title;
  final List<String> jobFields;
  final String description;
  final List<String> responsibilities;
  final List<String> qualifications;
  final List<String> skills;
  final int headcount;
  final int minAge;
  final int maxAge;
  final int minSalary;
  final int maxSalary;

  JobCreate({
    required this.title,
    required this.jobFields,
    required this.description,
    required this.responsibilities,
    required this.qualifications,
    required this.skills,
    required this.headcount,
    required this.minAge,
    required this.maxAge,
    required this.minSalary,
    required this.maxSalary,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'job_fields': jobFields,
      'description': description,
      'responsibilities': responsibilities,
      'qualifications': qualifications,
      'skills': skills,
      'headcount': headcount,
      'minAge': minAge,
      'maxAge': maxAge,
      'minSalary': minSalary,
      'maxSalary': maxSalary,
    };
  }
}
