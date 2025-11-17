// lib/services/user_profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserProfileService {
  final String baseUrl = "http://10.0.2.2:4000"; // update if needed

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final url = Uri.parse("$baseUrl/api/student/profile/$userId");
    print("📡 Fetching user profile from: $url");

    final response = await http.get(url);

    print("📩 Response Status Code: ${response.statusCode}");
    print("📄 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print("❌ JSON Decode Error: $e");
        throw Exception("Invalid JSON format in response");
      }
    } else {
      throw Exception("❌ Failed to load user profile. Status: ${response.statusCode}");
    }
  }
}
