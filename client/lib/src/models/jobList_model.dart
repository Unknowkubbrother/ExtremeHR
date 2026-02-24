class JobListItem {
  final int jobId;
  final String title;
  final String company;
  final String location;
  final int salary;

  JobListItem({
    required this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
  });

  JobListItem copyWith({
    int? jobId,
    String? title,
    String? company,
    String? location,
    int? salary,
  }) {
    return JobListItem(
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      salary: salary ?? this.salary,
    );
  }

  factory JobListItem.fromJson(Map<String, dynamic> json) {
    return JobListItem(
      jobId: json['id'],
      title: json['title'],
      company: json['company'],
      location: json['location'],
      salary: json['salary'],
    );
  }
}
