import 'package:client/src/models/interview_model.dart';

class CandidateCompareModel {
  final String interviewId;
  final String candidateId;
  final String candidateName;
  final InterviewSummary summary;

  CandidateCompareModel({
    required this.interviewId,
    required this.candidateId,
    required this.candidateName,
    required this.summary,
  });

  factory CandidateCompareModel.fromJson(Map<String, dynamic> json) {
    return CandidateCompareModel(
      interviewId: json['interview_id'].toString(),
      candidateId: json['candidate_id'].toString(),
      candidateName: json['candidate_name'] ?? 'Unknown',
      summary: InterviewSummary.fromJson(json['summary']),
    );
  }
}
