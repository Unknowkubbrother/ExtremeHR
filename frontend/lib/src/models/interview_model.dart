import 'package:client/src/models/status_enum.dart';

class InverViewCardModel {
  final String id;
  final Status state;
  final String title;
  final String company;

  InverViewCardModel({
    required this.id,
    required this.state,
    required this.title,
    required this.company,
  });

  factory InverViewCardModel.fromJson(Map<String, dynamic> json) {
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
        parsedState = Status.reject;
        break;
      case 'viewed':
        parsedState = Status.view;
        break;
      case 'accepted':
        parsedState = Status.accepted;
        break;
      default:
        parsedState = Status.waiting;
    }

    return InverViewCardModel(
      id: json['id'].toString(),
      state: parsedState,
      title: json['jobtitle'] ?? '',
      company: json['companyname'] ?? '',
    );
  }

  InverViewCardModel copyWith({
    String? id,
    Status? state,
    String? title,
    String? company,
  }) {
    return InverViewCardModel(
      id: id ?? this.id,
      company: company ?? this.company,
      title: title ?? this.title,
      state: state ?? this.state,
    );
  }
}

class ApplyJobModel {
  final bool isSuccess;

  ApplyJobModel({required this.isSuccess});

  factory ApplyJobModel.fromJson(Map<String, dynamic> json) {
    return ApplyJobModel(isSuccess: json['isSuccess']);
  }
}

class GeneratedInterviewQuestion {
  final String interviewQuestion;
  final String difficulty;
  final String competency;
  final int? id;

  GeneratedInterviewQuestion({
    required this.interviewQuestion,
    required this.difficulty,
    required this.competency,
    this.id,
  });

  factory GeneratedInterviewQuestion.fromJson(Map<String, dynamic> json) {
    return GeneratedInterviewQuestion(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? ''),
      interviewQuestion: json['interview_question']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      competency: json['competency']?.toString() ?? '',
    );
  }
}

class GeneratedInterviewQuestionResponse {
  final String message;
  final List<GeneratedInterviewQuestion> questions;

  GeneratedInterviewQuestionResponse({
    required this.message,
    required this.questions,
  });

  factory GeneratedInterviewQuestionResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final wrapper = json['questions'];
    final rawQuestions = wrapper is Map<String, dynamic>
        ? wrapper['questions']
        : null;
    final questionList = rawQuestions is List ? rawQuestions : const [];

    return GeneratedInterviewQuestionResponse(
      message: json['message']?.toString() ?? '',
      questions: questionList
          .whereType<Map>()
          .map(
            (item) => GeneratedInterviewQuestion.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class QuestionEvaluationResult {
  final int questionId;
  final double score;
  final String reason;

  QuestionEvaluationResult({
    required this.questionId,
    required this.score,
    required this.reason,
  });

  factory QuestionEvaluationResult.fromJson(Map<String, dynamic> json) {
    return QuestionEvaluationResult(
      questionId: json['question_id'] is num
          ? (json['question_id'] as num).toInt()
          : int.tryParse(json['question_id']?.toString() ?? '') ?? 0,
      score: json['score'] is num
          ? (json['score'] as num).toDouble()
          : double.tryParse(json['score']?.toString() ?? '') ?? 0,
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class InterviewSummaryPoint {
  final String title;
  final String evidence;

  InterviewSummaryPoint({required this.title, required this.evidence});

  factory InterviewSummaryPoint.fromJson(Map<String, dynamic> json) {
    return InterviewSummaryPoint(
      title: json['title']?.toString() ?? '',
      evidence: json['evidence']?.toString() ?? '',
    );
  }
}

class InterviewSummaryEvidence {
  final String experience;
  final String communication;
  final String technical;

  InterviewSummaryEvidence({
    required this.experience,
    required this.communication,
    required this.technical,
  });

  factory InterviewSummaryEvidence.fromJson(Map<String, dynamic> json) {
    return InterviewSummaryEvidence(
      experience: json['experience']?.toString() ?? '',
      communication: json['communication']?.toString() ?? '',
      technical: json['technical']?.toString() ?? '',
    );
  }
}

class InterviewSummary {
  final double totalScore;
  final double experienceScore;
  final double communicationScore;
  final double technicalScore;
  final String recommendation;
  final double confidence;
  final List<InterviewSummaryPoint> strengths;
  final List<InterviewSummaryPoint> weaknesses;
  final List<String> redFlags;
  final InterviewSummaryEvidence evidence;
  final String suggestionSummary;
  final String nextStep;

  InterviewSummary({
    required this.totalScore,
    required this.experienceScore,
    required this.communicationScore,
    required this.technicalScore,
    required this.recommendation,
    required this.confidence,
    required this.strengths,
    required this.weaknesses,
    required this.redFlags,
    required this.evidence,
    required this.suggestionSummary,
    required this.nextStep,
  });

  factory InterviewSummary.fromJson(Map<String, dynamic> json) {
    final strengths = json['strengths'];
    final weaknesses = json['weaknesses'];
    final redFlags = json['red_flags'];
    final evidenceJson = json['evidence'];

    return InterviewSummary(
      totalScore: _parseDouble(json['total_score']),
      experienceScore: _parseDouble(json['experience_score']),
      communicationScore: _parseDouble(json['communication_score']),
      technicalScore: _parseDouble(json['technical_score']),
      recommendation: json['recommendation']?.toString() ?? '',
      confidence: _parseDouble(json['confidence']),
      strengths: strengths is List
          ? strengths
                .whereType<Map>()
                .map(
                  (item) => InterviewSummaryPoint.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      weaknesses: weaknesses is List
          ? weaknesses
                .whereType<Map>()
                .map(
                  (item) => InterviewSummaryPoint.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      redFlags: redFlags is List
          ? redFlags.map((item) => item.toString()).toList()
          : const [],
      evidence: evidenceJson is Map<String, dynamic>
          ? InterviewSummaryEvidence.fromJson(evidenceJson)
          : InterviewSummaryEvidence(
              experience: '',
              communication: '',
              technical: '',
            ),
      suggestionSummary: json['suggestion_summary']?.toString() ?? '',
      nextStep: json['next_step']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
