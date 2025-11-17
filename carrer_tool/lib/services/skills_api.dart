import 'dart:convert';
import 'package:http/http.dart' as http;

class SkillsApi {
  final String baseUrl = "http://10.0.2.2:4000/api/student";

  /// Fetch skills for a user
  Future<List<String>> fetchSkills(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/profile/$userId");
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final skills = List<String>.from(data['skills'] ?? []);
        return skills;
      } else {
        print("❌ Fetch skills failed: ${resp.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching skills: $e");
      return [];
    }
  }

  /// Add a skill to the user profile
  Future<bool> addSkill(String userId, String skill) async {
    try {
      final url = Uri.parse("$baseUrl/profile/skills/add");

      final body = json.encode({
        "userId": userId,
        "skill": skill,
      });

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        print("✅ Skill added successfully");
        return true;
      } else {
        print("❌ Add skill failed: ${resp.statusCode} ${resp.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error adding skill: $e");
      return false;
    }
  }

  /// Remove a skill from the user profile
  Future<bool> removeSkill(String userId, String skill) async {
    try {
      final url = Uri.parse("$baseUrl/profile/skills/remove");

      final body = json.encode({
        "userId": userId,
        "skill": skill,
      });

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (resp.statusCode == 200) {
        print("✅ Skill removed successfully");
        return true;
      } else {
        print("❌ Remove skill failed: ${resp.statusCode} ${resp.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error removing skill: $e");
      return false;
    }
  }
}
