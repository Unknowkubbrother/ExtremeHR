import 'package:client/src/models/status_enum.dart';

class HRCandidateModel {
  final String id;
  final Status state;
  final String candidateName;
  final String candidateId;
  final DateTime createdAt;
  final String jobId;

  HRCandidateModel({
    required this.id,
    required this.state,
    required this.candidateName,
    required this.candidateId,
    required this.createdAt,
    required this.jobId,
  });

  factory HRCandidateModel.fromJson(Map<String, dynamic> json) {
    Status parsedState = Status.waiting;
    String statusStr = (json['status'] ?? '').toString().toLowerCase();
    switch (statusStr) {
      case 'waiting':
        parsedState = Status.waiting;
        break;
      case 'interview':
        parsedState = Status.interview;
        break;
      case 'rejected':
      case 'reject':
        parsedState = Status.reject;
        break;
      case 'viewed':
      case 'view':
        parsedState = Status.view;
        break;
      case 'accepted':
        parsedState = Status.accepted;
        break;
      default:
        parsedState = Status.waiting;
    }

    return HRCandidateModel(
      id: json['id'].toString(),
      state: parsedState,
      candidateName: json['candidate_name'] ?? 'Unknown',
      candidateId: json['candidate_id'].toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      jobId: json['job_id'].toString(),
    );
  }
}
