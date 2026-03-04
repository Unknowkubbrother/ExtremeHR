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
}
