import 'dart:convert';
import 'package:client/src/models/jobModify_model.dart';
import 'package:client/src/models/job_hr_model.dart';
import 'package:http/http.dart' as http;
import 'package:client/src/models/jobList_model.dart';
import 'package:client/src/models/jobDetail_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JobServices {
  Future<List<JobListItem>> getJobs(String token, {String? filter}) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    var url = '$apiUrl/jobs/';
    if (filter != null && filter != "All") {
      url += '?filter=${Uri.encodeComponent(filter)}';
    }
    final response = await http.get(
      Uri.parse(url),
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

  Future<JobDetail> createJob(String token, JobCreate job) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/jobs_hr/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(job.toJson()),
    );
    if (response.statusCode == 201) {
      return JobDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create job');
    }
  }

  Future<JobDetail> updateJob(String token, JobUpdate job) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/jobs_hr/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(job.toJson()),
    );
    if (response.statusCode == 200) {
      return JobDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update job');
    }
  }

  Future<List<JobHR>> getJobsByHR(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/jobs_hr/hr'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => JobHR.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get HR jobs');
    }
  }

  Future<JobStats> getHRStats(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/jobs_hr/hr/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return JobStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get HR stats');
    }
  }

  Future<bool> deleteJob(String token, int jobId) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/jobs_hr/delete/$jobId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete job');
    }
  }

  Future<List<Map<String, dynamic>>> searchJobs(
    String token,
    String query, {
    String? filter,
  }) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

    final Map<String, dynamic> body = {'query': query};
    if (filter != null && filter != "All") {
      body['filter'] = filter;
    }

    final response = await http.post(
      Uri.parse('$apiUrl/search/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['message']);
    } else {
      throw Exception('Failed to search jobs');
    }
  }

  Future<List<RecentApplyResponse>> getHRRecentApply(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/jobs_hr/hr/recent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => RecentApplyResponse.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to get HR recent apply');
    }
  }
}
