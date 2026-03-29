class CandidateSearchResultModel {
  final int candidateId;
  final int interviewId;
  final double score;
  final String reason;
  final String candidateName;
  final List<String> evidence;

  CandidateSearchResultModel({
    required this.candidateId,
    required this.interviewId,
    required this.score,
    required this.reason,
    required this.candidateName,
    required this.evidence,
  });

  factory CandidateSearchResultModel.fromJson(Map<String, dynamic> json) {
    return CandidateSearchResultModel(
      candidateId: int.tryParse(json['candidate_id'].toString()) ?? 0,
      interviewId: int.tryParse(json['interview_id'].toString()) ?? 0,
      score: double.tryParse(json['score'].toString()) ?? 0.0,
      reason: json['reason'] ?? '',
      candidateName: json['candidate_name'] ?? 'Unknown',
      evidence: List<String>.from(json['evidence'] ?? []),
    );
  }
}
