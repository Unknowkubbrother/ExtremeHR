class JobHR {
  final int id;
  final String title;
  final String company;
  final int candidateCount;
  final int approvedCount;
  final int interviewCount;
  final int waitingCount;
  final int headcount;
  final DateTime postedAt;

  JobHR({
    required this.id,
    required this.title,
    required this.company,
    required this.candidateCount,
    required this.approvedCount,
    required this.interviewCount,
    required this.waitingCount,
    required this.headcount,
    required this.postedAt,
  });

  factory JobHR.fromJson(Map<String, dynamic> json) {
    return JobHR(
      id: json['id'],
      title: json['title'],
      company: json['company'],
      candidateCount: json['candidate_count'] ?? 0,
      approvedCount: json['approved_count'] ?? 0,
      interviewCount: json['interview_count'] ?? 0,
      waitingCount: json['waiting_count'] ?? 0,
      headcount: json['headcount'] ?? 0,
      postedAt: DateTime.parse(json['postedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'candidate_count': candidateCount,
      'approved_count': approvedCount,
      'interview_count': interviewCount,
      'waiting_count': waitingCount,
      'headcount': headcount,
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

class RecentApplyResponse {
  final int id;
  final String title;
  final String candidateName;
  final DateTime dateAt;

  RecentApplyResponse({
    required this.id,
    required this.title,
    required this.candidateName,
    required this.dateAt,
  });

  factory RecentApplyResponse.fromJson(Map<String, dynamic> json) {
    return RecentApplyResponse(
      id: json['id'],
      title: json['title'],
      candidateName: json['candidate_name'],
      dateAt: DateTime.parse(json['date_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'candidate_name': candidateName,
      'date_at': dateAt,
    };
  }
}
