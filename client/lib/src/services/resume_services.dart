import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/src/models/personal_info_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResumeService {
  final String _baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';

  Future<PersonalInformation> getMyResume(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resume/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return PersonalInformation.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      // Return empty data if resume doesn't exist yet
      return PersonalInformation(
        fullName: "",
        age: null,
        phone: null,
        email: null,
        address: null,
        skills: [],
        education: [],
        experience: [],
        projects: [],
      );
    } else {
      throw Exception('Failed to load resume: ${response.body}');
    }
  }

  Future<PersonalInformation> saveResume(
    String token,
    PersonalInformation data,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/resume/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return PersonalInformation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save resume: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> uploadResume(
    String token,
    String filePath,
  ) async {
    final uri = Uri.parse('$_baseUrl/resume/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }

  Future<PersonalInformation> getCandidateResume(
    String token,
    int candidateId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resume/candidate/$candidateId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return PersonalInformation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get candidate resume');
    }
  }
}
