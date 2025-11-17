import 'dart:convert';
import 'package:http/http.dart' as http;

class LeaderboardApi {
  final String baseUrl = "http://10.0.2.2:4000/api/scalculate";

  /// Fetch leaderboard from backend for a company job role
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String jobPostId,
    required Map<String, dynamic> weights, // 👈 change type to Map, not String
  }) async {
    try {
      print("📌 LeaderboardApi fetchLeaderboard called:");
      print("JobPostId: $jobPostId");
      print("Weights: $weights");

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jobPostId': jobPostId,
          'weights': weights, // 👈 send as JSON object
        }),
      );

      print("📌 Response status: ${response.statusCode}");
      print("📌 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        final Map<String, dynamic> err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Unexpected error');
      }
    } catch (e) {
      print("❌ Error fetching leaderboard: $e");
      rethrow;
    }
  }
}
