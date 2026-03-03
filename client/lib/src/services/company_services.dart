import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/src/models/company_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CompanyServices {
  Future<CompanyModel?> getMyCompany(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/company/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body == null) return null;
      return CompanyModel.fromJson(body);
    } else {
      throw Exception('Failed to get company');
    }
  }

  Future<CompanyModel> updateMyCompany(
    String token,
    String name,
    String location,
  ) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.post(
      Uri.parse('$apiUrl/company/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'location': location}),
    );
    if (response.statusCode == 200) {
      return CompanyModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update company');
    }
  }
}
