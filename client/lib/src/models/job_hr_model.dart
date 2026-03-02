class JobHR {
  final int id;
  final String title;
  final String company;
  final int candidateCount;

  JobHR({
    required this.id,
    required this.title,
    required this.company,
    required this.candidateCount,
  });

  factory JobHR.fromJson(Map<String, dynamic> json) {
    return JobHR(
      id: json['id'],
      title: json['title'],
      company: json['company'],
      candidateCount: json['candidate_count'] ?? 0,
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
