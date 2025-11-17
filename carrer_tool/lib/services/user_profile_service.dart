import 'dart:convert';
import 'package:http/http.dart' as http;

class UserProfileService {
  final String baseUrl = "http://10.0.2.2:4000/api/student"; // Replace with your actual backend route

  /// Fetch user profile from backend using userId
  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/profile/$userId'); // e.g., GET /api/student/profile/:userId
      print("🌐 Fetching user profile from: $url");

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print("📩 Status Code: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("✅ Successfully fetched user profile for ID: $userId");
        return data;
      } else {
        final Map<String, dynamic> err = jsonDecode(response.body);
        print("⚠️ Server returned an error: ${err['message']}");
        throw Exception(err['message'] ?? 'Failed to fetch user profile');
      }
    } catch (e) {
      print("❌ Error fetching user profile: $e");
      rethrow;
    }
  }
}
