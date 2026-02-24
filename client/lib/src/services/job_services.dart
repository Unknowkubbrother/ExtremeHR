import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/src/models/jobList_model.dart';
import 'package:client/src/models/jobDetail_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JobServices {
  Future<List<JobListItem>> getJobs(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/jobs/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => JobListItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get jobs');
    }
  }

  Future<JobDetail> getJobDetail(String token, int jobId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/jobs/$jobId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return JobDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get job detail');
    }
  }
}
