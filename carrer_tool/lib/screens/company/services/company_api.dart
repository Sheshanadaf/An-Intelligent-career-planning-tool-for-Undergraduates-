// lib/services/company_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

final storage = FlutterSecureStorage();
const String baseUrl = "YOUR_API_BASE_URL";

class CompanyApi {
  final String baseUrl = "http://10.0.2.2:4000/api";
  final storage = const FlutterSecureStorage();


  /// ✅ UPDATE COMPANY PROFILE
Future<Map<String, dynamic>?> updateProfileWithImage({
  required String name,
  required String reg,
  required String dis,
  File? logoFile,
}) async {
  final companyId = await storage.read(key: 'userId');
  if (companyId == null) return null;

  try {
    var uri = Uri.parse('$baseUrl/company/profile/update/$companyId');
    var request = http.MultipartRequest('PUT', uri);

    request.fields['companyName'] = name;
    request.fields['companyReg'] = reg;
    request.fields['companyDis'] = dis;

    if (logoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('companyLogo', logoFile.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      // ✅ Parse backend JSON and return it
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      return null;
    }
  } catch (e) {
    print("Error updating profile: $e");
    return null;
  }
}



  /// ✅ CREATE JOB POST
  Future<bool> createJobPost(Map<String, dynamic> data) async {
    final companyId = await storage.read(key: 'userId');

    print("🟦 Sending Job Post Request...");
    print("➡️ companyId ID: $companyId");
    print("➡️ Payload: ${jsonEncode({...data, 'companyId': companyId})}");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobpost'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({...data, 'companyId': companyId}),
      );

      print("📨 Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Job post created successfully!");
        return true;
      } else {
        print("❌ Failed to create job post. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("🚨 Error creating job post: $e");
      return false;
    }
  }


  /// ✅ DELETE JOB POST
Future<bool> deleteJobPost(String postId) async {
  final companyId = await storage.read(key: 'userId');

  print("🟦 Deleting Job Post...");
  print("➡️ Post ID: $postId");
  print("➡️ Company ID: $companyId");

  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/jobpost/$postId'),
      headers: {'Content-Type': 'application/json'},
    );

    print("📨 Status Code: ${response.statusCode}");
    print("📩 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      print("✅ Job post deleted successfully!");
      return true;
    } else {
      print("❌ Failed to delete job post. Status: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("🚨 Error deleting job post: $e");
    return false;
  }
}

  /// ✅ FETCH COMPANY JOB POSTS
  Future<List<dynamic>> fetchCompanyPosts() async {
    final companyId = await storage.read(key: 'userId');

    print("🟦 Fetching job posts for user ID: $companyId");

    try {
      final response = await http.get(Uri.parse('$baseUrl/jobpost/$companyId'));

      print("📨 Status Code: ${response.statusCode}");
      print("📩 Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final posts = decoded['jobPosts'] ?? decoded ?? [];
        print("🟩 Loaded ${posts.length} job posts");
        return posts;
      } else {
        print("❌ Failed to fetch company posts: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🚨 Error fetching company posts: $e");
      return [];
    }
  }

  /// ✅ FETCH COMPANY PROFILE
  Future<Map<String, dynamic>?> fetchCompanyProfile() async {
    final companyId = await storage.read(key: 'userId');
    if (companyId == null) {
      print("❌ No userId found in storage");
      return null;
    }

    final url = Uri.parse('$baseUrl/company/profile/$companyId');
    print("🌐 Fetching company profile from: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Company Profile Data: $data");
        return data;
      } else {
        print("❌ Failed to load company profile. Status: ${response.statusCode}");
        print("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching company profile: $e");
      return null;
    }
  }

  /// ✅ UPDATE JOB POST (NEW)
  Future<bool> updateJobPost(String postId, Map<String, dynamic> updatedData) async {
    final companyId = await storage.read(key: 'userId');

    print("🟦 Updating Job Post...");
    print("➡️ Post ID: $postId");
    print("➡️ Payload: ${jsonEncode({...updatedData, 'companyId': companyId})}");

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jobpost/$postId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({...updatedData, 'companyId': companyId}),
      );

      print("📨 Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Job post updated successfully!");
        return true;
      } else {
        print("❌ Failed to update job post. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("🚨 Error updating job post: $e");
      return false;
    }
  }
}


