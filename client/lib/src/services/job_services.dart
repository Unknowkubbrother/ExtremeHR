import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/src/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JobServices {
  Future<UserModel> me(String token) async {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000';
    final response = await http.get(
      Uri.parse('$apiUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user');
    }
  }
}
