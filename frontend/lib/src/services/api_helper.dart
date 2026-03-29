import 'package:client/src/services/auth_storage.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  /// Checks if the response status is 401 (Unauthorized) and triggers logout if so.
  /// Returns the original response if authorized.
  static http.Response handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      AuthStorage.logout();
    }
    return response;
  }
}
