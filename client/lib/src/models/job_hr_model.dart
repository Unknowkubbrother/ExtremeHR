class JobHR {
  final int id;
  final String title;
  final String company;
  final int candidateCount;
  final DateTime postedAt;

  JobHR({
    required this.id,
    required this.title,
    required this.company,
    required this.candidateCount,
    required this.postedAt,
  });

  factory JobHR.fromJson(Map<String, dynamic> json) {
    return JobHR(
      id: json['id'],
      title: json['title'],
      company: json['company'],
      candidateCount: json['candidate_count'] ?? 0,
      postedAt: DateTime.parse(json['postedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'candidate_count': candidateCount,
    };
  }
}

class JobStats {
  final int activeJobs;
  final int interviews;
  final int approved;

  JobStats({
    required this.activeJobs,
    required this.interviews,
    required this.approved,
  });

  factory JobStats.fromJson(Map<String, dynamic> json) {
    return JobStats(
      activeJobs: json['active_jobs'],
      interviews: json['interviews'],
      approved: json['approved'],
    );
  }
}
