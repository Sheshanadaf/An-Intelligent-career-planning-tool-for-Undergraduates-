// lib/services/user_marks_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserMarksService {
  final String baseUrl = "http://10.0.2.2:4000";

  Future<void> updateMarks({
    required String userId,
    required String jobPostId,
    required String section, // "project" or "license"
    required String itemId, // specific project/license ID
    required double value,
  }) async {
    final url = Uri.parse("$baseUrl/api/student/profile/marks/$userId");

    final body = jsonEncode({
      "section": section,
      "itemId": itemId,
      "jobPostId": jobPostId,
      "value": value,
    });

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update marks");
    }
  }
}
