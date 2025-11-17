import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart'; // adjust the path to your auth file

class RankApi {
  static const String baseUrl = "http://10.0.2.2:4000";
  static List<dynamic> _cachedJobPosts = [];
  static String? _cachedUserId;

  static void clearCache() {
  _cachedJobPosts = [];
  _cachedUserId = null;
  print("🧹 Cache cleared.");
}


  /// 🔹 Fetch all job posts for the logged-in user (only once)
  static Future<void> _fetchAllJobPosts() async {
    if (_cachedJobPosts.isNotEmpty) return;
    final auth = AuthService();

    final userId = await auth.getUserId(); // ✅ your existing method
    if (userId == null || userId.isEmpty) {
      throw Exception("User ID not found in local auth storage");
    }

    _cachedUserId = userId;
    final url = Uri.parse("$baseUrl/api/jobpost/jobs/$userId");
    print("📡 Fetching all job posts for userId: $userId");

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      _cachedJobPosts = body['jobPosts'] ?? [];
      print("jjjjjjjjjj $body");
      print("✅ Job posts fetched successfully (${_cachedJobPosts.length})");
    } else {
      print("❌ Failed to fetch job posts. Status: ${res.statusCode}");
      print("Response: ${res.body}");
      throw Exception("Failed to fetch job posts");
    }
  }

  /// 🔹 Get all unique companies
  static Future<List<String>> fetchCompanies() async {
    await _fetchAllJobPosts();

    final companies = _cachedJobPosts
        .map((job) => job['companyName']?.toString())
        .where((name) => name != null && name.isNotEmpty)
        .toSet()
        .toList();

    print("🏢 Companies fetched: $companies");
    return companies.cast<String>();
  }

  /// 🔹 Get job roles for a selected company
  static Future<List<String>> fetchJobRoles(String company) async {
    await _fetchAllJobPosts();

    final roles = _cachedJobPosts
        .where((job) =>
            job['companyName']?.toString().toLowerCase() ==
            company.toLowerCase())
        .map((job) => job['jobRole']?.toString())
        .where((role) => role != null && role.isNotEmpty)
        .toSet()
        .toList();

    print("🎯 Job roles for $company: $roles");
    return roles.cast<String>();
  }

  /// 🔹 Get detailed info for a specific company & job role
  /// 🔹 Get detailed info for a specific company & job role
  static Future<Map<String, dynamic>> fetchJobDetails({
    required String company,
    required String jobRole,
  }) async {
    await _fetchAllJobPosts();

    final matchedJob = _cachedJobPosts.firstWhere(
      (job) =>
          (job['companyName']?.toString().toLowerCase() == company.toLowerCase()) &&
          (job['jobRole']?.toString().toLowerCase() == jobRole.toLowerCase()),
      orElse: () => {},
    );

    if (matchedJob.isEmpty) {
      print("⚠️ No job post found for $company - $jobRole");
      throw Exception("No matching job post found");
    }

    print("📋 Matched Job: $matchedJob");

    // 🧠 Clean and format data for frontend
    final description = matchedJob["description"] ?? "No description available";

    // Backend sends `skills` as comma-separated string → convert to List
    final skillsRaw = matchedJob["skills"];
    final skills = skillsRaw is String
        ? skillsRaw.split(',').map((s) => s.trim()).toList()
        : (skillsRaw is List ? List<String>.from(skillsRaw) : []);

    final certifications = matchedJob["certifications"] ?? "No certifications info";
    final details = matchedJob["details"] ?? "Not specified";
    final jobPostId = matchedJob["_id"] ?? "Not specified";
    final weights = matchedJob["weights"] ?? {};

    print("🧩 Returning job details: $jobPostId | $description | $skills | $certifications | $details | $weights");

    return {
      "description": description,
      "skills": skills,
      "certifications": certifications,
      "details": details,
      "weights": weights,
      "jobPostId":jobPostId,
    };
  }



  /// 🔹 Dummy submit rank (will connect backend later)
  static Future<bool> submitRank({
    required String company,
    required String jobRole,
    required Map<String, int> weights,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    print("📤 Submitted Rank Data:");
    print("Company: $company");
    print("Job Role: $jobRole");
    print("Weights: $weights");
    return true;
  }
}
