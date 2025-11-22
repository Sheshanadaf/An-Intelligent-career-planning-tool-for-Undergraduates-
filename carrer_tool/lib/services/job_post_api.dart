import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class JobPostsApi {
  final String baseUrl = "http://10.0.2.2:4000"; // adjust if needed

  // 🟢 Get all job posts
  Future<List<dynamic>> fetchAllJobs() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/jobpost"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data;
      } else {
        throw Exception("Failed to fetch job posts: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching all jobs: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> fetchRecommendedJobs(String userId) async {
  try {
    final res = await http.get(Uri.parse("$baseUrl/api/jobPost/recommend/$userId"));
    print("📥 HTTP GET /jobPosts/recommend/$userId -> Status: ${res.statusCode}");
    print("📦 Response body: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print("💡 Parsed JSON type: ${data.runtimeType}");

      // Extract the array from your JSON object
      if (data is Map<String, dynamic> && data.containsKey('recommendedJobs')) {
        print("✅ Found recommendedJobs array with length: ${data['recommendedJobs'].length}");
        return data['recommendedJobs'] as List<dynamic>;
      }

      print("⚠️ No 'recommendedJobs' key found in response.");
      return [];
    } else {
      debugPrint("❌ Failed to fetch recommended jobs: ${res.statusCode}");
      return [];
    }
  } catch (e) {
    debugPrint("⚠️ Error fetching recommended jobs: $e");
    return [];
  }
}

  // 🟡 Get jobs added by user
  Future<List<dynamic>> fetchAddedJobs(String userId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/jobpost/jobs/$userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data.containsKey('jobPosts')) {
          return data['jobPosts'];
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching added jobs: $e");
      return [];
    }
  }

  // 🔵 Add job to user
  Future<bool> addJobToUser(String userId, String jobPostId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/jobpost"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "jobPostId": jobPostId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("⚠️ Error adding job: $e");
      return false;
    }
  }

  // 🔴 Remove job from user
  Future<bool> removeJobFromUser(String userId, String jobPostId) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/api/jobpost/remove"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "jobPostId": jobPostId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("⚠️ Error removing job: $e");
      return false;
    }
  }
}
