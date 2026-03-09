import 'dart:convert';
import 'package:client/src/models/interview_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:client/src/models/hr_candidate_model.dart';

class InterviewService {
  Future<List<InverViewCardModel>> getInterviews(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/interview/interviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => InverViewCardModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get interviews');
    }
  }

  Future<ApplyJobModel> applyJob(String token, String jobId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview/apply/$jobId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ApplyJobModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<ApplyJobModel> cancelJob(String token, String jobId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview/cancel/$jobId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ApplyJobModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<List<HRCandidateModel>> getJobCandidates(
    String token,
    String jobId,
  ) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/interview/hr/job/$jobId/candidates'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => HRCandidateModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get job candidates');
    }
  }

  Future<ApplyJobModel> rejectInterview(
    String token,
    String interviewId,
  ) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview/hr/interview/$interviewId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ApplyJobModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<ApplyJobModel> acceptInterview(
    String token,
    String interviewId,
  ) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview/hr/interview/$interviewId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ApplyJobModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<ApplyJobModel> interviewCandidate(
    String token,
    String interviewId,
  ) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview/hr/interview/$interviewId/interview'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ApplyJobModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<ApplyJobModel> endInterview(String token, String interviewId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview/hr/interview/$interviewId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return ApplyJobModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  Future<void> getInterviewContext(String token, String interviewId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/interview-llm/context/$interviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get interview context');
    }
  }

  Future<GeneratedInterviewQuestionResponse> generateInterviewQuestions(
    String token,
    String interviewId,
    String hrPrompt,
  ) async {
    final parsedInterviewId = int.tryParse(interviewId);
    if (parsedInterviewId == null) {
      throw Exception('Invalid interview id');
    }

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview-llm/generate-question'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'interview_id': parsedInterviewId,
        'hr_prompt': hrPrompt,
      }),
    );

    dynamic responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (_) {
      responseBody = response.body;
    }

    if (response.statusCode == 200 && responseBody is Map<String, dynamic>) {
      return GeneratedInterviewQuestionResponse.fromJson(responseBody);
    }

    throw Exception(_extractErrorMessage(responseBody));
  }

  String _extractErrorMessage(dynamic responseBody) {
    if (responseBody is Map<String, dynamic>) {
      final detail = responseBody['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }

      final message = responseBody['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    if (responseBody is String && responseBody.isNotEmpty) {
      return responseBody;
    }

    return 'Failed to generate interview questions';
  }

  Future<InterviewSummary> getInterviewSummary(
    String token,
    String interviewId,
  ) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/interview-llm/summary/$interviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    dynamic responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (_) {
      responseBody = response.body;
    }

    if (response.statusCode == 200 && responseBody is Map<String, dynamic>) {
      return InterviewSummary.fromJson(responseBody);
    }

    throw Exception(_extractErrorMessage(responseBody));
  }

  Future<InterviewSummary> generateInterviewSummary(
    String token,
    String interviewId,
  ) async {
    final parsedInterviewId = int.tryParse(interviewId);
    if (parsedInterviewId == null) {
      throw Exception('Invalid interview id');
    }

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/interview-llm/generate-summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'interview_id': parsedInterviewId}),
    );

    dynamic responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (_) {
      responseBody = response.body;
    }

    if (response.statusCode == 200 && responseBody is Map<String, dynamic>) {
      return InterviewSummary.fromJson(responseBody);
    }

    throw Exception(_extractErrorMessage(responseBody));
  }
}
