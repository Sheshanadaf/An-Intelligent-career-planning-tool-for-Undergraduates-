import 'dart:convert';
import 'package:http/http.dart' as http;

class JobPostsApi {
  final String baseUrl = "http://10.0.2.2:4000"; // 🔧 Change if needed

  // 🟢 Get all job posts
  Future<List<dynamic>> fetchAllJobs() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/jobpost"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("📦 Received Job Posts (${data.length} items):");
        print(data);
        return data;
      } else {
        print("❌ Failed to fetch job posts. Status: ${res.statusCode}");
        print("Response body: ${res.body}");
        throw Exception("Failed to fetch job posts");
      }
    } catch (e) {
      print("⚠️ Error fetching all jobs: $e");
      rethrow;
    }
  }

  // 🟢 Add job to user’s profile
  Future<bool> addJobToUser(String userId, String jobPostId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/jobpost"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "jobPostId": jobPostId,
        }),
      );

      if (res.statusCode == 200) {
        print("✅ Job added successfully: ${res.body}");
        return true;
      } else {
        print("❌ Failed to add job: ${res.statusCode} -> ${res.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error adding job: $e");
      return false;
    }
  }

  // 🟣 Get recommended jobs for a specific user
  Future<List<dynamic>> fetchRecommendedJobs(String userId) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/jobpostp/recommended/$userId"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("💡 Recommended Jobs: ${data.length}");
        return data;
      } else {
        print("❌ Failed to fetch recommended jobs: ${res.statusCode}");
        throw Exception("Failed to fetch recommended jobs");
      }
    } catch (e) {
      print("⚠️ Error fetching recommended jobs: $e");
      rethrow;
    }
  }

  // 🟡 Get all jobs added by the user
  Future<List<dynamic>> fetchAddedJobs(String userId) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/api/jobpost/jobs/$userId"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // ✅ Directly read the jobPosts array
      if (data is Map<String, dynamic> && data.containsKey('jobPosts')) {
        final List<dynamic> jobs = data['jobPosts'];
        print("📋 User's added jobs (${jobs.length} items):");
        return jobs;
      }

      print("⚠️ Unexpected response format: $data");
      return [];
    } else {
      print("❌ Failed to fetch user's added jobs: ${res.statusCode}");
      print("Response: ${res.body}");
      return [];
    }
  } catch (e) {
    print("⚠️ Error fetching user's added jobs: $e");
    return [];
  }
}



  // 🔴 Remove job from user’s added list
  Future<bool> removeJobFromUser(String userId, String jobPostId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/api/jobpost/remove"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "jobPostId": jobPostId,
        }),
      );

      if (res.statusCode == 200) {
        print("🗑️ Job removed successfully: ${res.body}");
        return true;
      } else {
        print("❌ Failed to remove job: ${res.statusCode} -> ${res.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error removing job: $e");
      return false;
    }
  }
}
