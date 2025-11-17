import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';


class AuthService {
  final String baseUrl = 'http://10.0.2.2:4000/api/auth'; // emulator: 10.0.2.2
  
  final storage = FlutterSecureStorage();

  // =========================
  // REGISTER
  // =========================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? companyName,
    String? companyReg,
    File? companyLogo, // optional
  }) async {
    // ---------- Create multipart request ----------
    final uri = Uri.parse('$baseUrl/register');
    var request = http.MultipartRequest('POST', uri);

    // Add common fields
    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['role'] = role;

    // Add student-specific fields
    if (role == 'student' && phone != null) {
      request.fields['phone'] = phone;
    }

    // Add company-specific fields
    if (role == 'company') {
      if (companyName != null) request.fields['companyName'] = companyName;
      if (companyReg != null) request.fields['companyReg'] = companyReg;

      // Attach logo if provided
      if (companyLogo != null) {
        final mimeType = lookupMimeType(companyLogo.path) ?? 'image/jpeg';
        final mimeSplit = mimeType.split('/');
        final file = await http.MultipartFile.fromPath(
          'companyLogo',
          companyLogo.path,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        );
        request.files.add(file);
      }
    }

    // ---------- Debug: Print all sent fields ----------
    debugPrint('--- REGISTER REQUEST ---');
    request.fields.forEach((key, value) => debugPrint('$key: $value'));
    if (request.files.isNotEmpty) {
      debugPrint('Files: ${request.files.map((f) => f.filename).join(', ')}');
    }
    debugPrint('------------------------');

    // Send request
    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    final data = _processResponse(res);

    // Save tokens if successful
    if (data.containsKey('accessToken')) {
      await storage.write(key: 'accessToken', value: data['accessToken']);
      await storage.write(key: 'refreshToken', value: data['refreshToken']);
      await storage.write(key: 'role', value: data['user']['role']);
      await storage.write(key: 'userId', value: data['user']['id']);
      debugPrint("🔐 Tokens saved. UserId: ${data['user']['id']}");
    }

    // Debug: Print response from backend
    debugPrint('--- REGISTER RESPONSE ---');
    debugPrint(res.body);
    debugPrint('-------------------------');

    return data;
  }

  // =========================
  // LOGIN
  // =========================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    debugPrint("SERVER RESPONSE: ${res.body}");

    final data = _processResponse(res);

    if (data.containsKey('accessToken')) {
      await storage.write(key: 'accessToken', value: data['accessToken']);
      await storage.write(key: 'refreshToken', value: data['refreshToken']);
      await storage.write(key: 'role', value: data['user']['role']);
      await storage.write(key: 'userId', value: data['user']['id']);
      debugPrint("🔐 Tokens saved. UserId: ${data['user']['id']}");
    }

    return data;
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  Future<Map<String, dynamic>> forgot(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/forgot'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _processResponse(res);
  }

  // =========================
  // RESET PASSWORD
  // =========================
  Future<Map<String, dynamic>> reset(String token, String id, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'id': id, 'newPassword': newPassword}),
    );
    return _processResponse(res);
  }

  // =========================
  // RESPONSE HANDLER
  // =========================
  Map<String, dynamic> _processResponse(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Error ${res.statusCode}');
  }

  // =========================
  // STORAGE HELPERS
  // =========================
  Future<String?> getRole() async => await storage.read(key: 'role');

  Future<String?> getUserId() async => await storage.read(key: 'userId');

  Future<void> logout() async => await storage.deleteAll();

  //// ---------------- CREATE COMPANY PROFILE ----------------
  Future<bool> createCompanyProfile(Map<String, dynamic> companyProfile) async {
    const String url = "http://10.0.2.2:4000/api/company/profile";

    // ✅ No need to redeclare storage — already exists in class
    final token = await storage.read(key: 'accessToken');
    final companyId = await storage.read(key: 'userId');

    if (token == null || companyId == null) {
      debugPrint("❌ Missing token or companyId");
      return false;
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      // ✅ Required fields
      request.fields['companyId'] = companyProfile["companyId"] ?? '';
      request.fields['companyName'] = companyProfile["companyName"] ?? '';
      request.fields['email'] = companyProfile["email"] ?? '';
      request.fields['companyReg'] = companyProfile["companyReg"] ?? '';
      request.fields['role'] = companyProfile["role"] ?? 'company';
      request.fields['password'] = companyProfile["password"] ?? '';

      // ✅ Optional: Attach company logo if available
      if (companyProfile["companyLogo"] != null) {
        final file = companyProfile["companyLogo"] is File
            ? companyProfile["companyLogo"]
            : File(companyProfile["companyLogo"]); // ✅ convert from path to File
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        final mimeSplit = mimeType.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'companyLogo',
            file.path,
            contentType: MediaType(mimeSplit[0], mimeSplit[1]),
          ),
        );
      }

      // ✅ Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("📩 Company Profile submitted -> ${request.fields}");
      debugPrint("🖼️ Attached files -> ${request.files.map((f) => f.filename).toList()}");
      debugPrint("✅ Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("🏢 Company profile created successfully: ${data['profile']}");
        return true;
      } else {
        debugPrint("❌ Failed with status ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error submitting company profile: $e");
      return false;
    }
  }

}

