import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:4000/api/auth'; // Android emulator
  final storage = const FlutterSecureStorage();

  // ---------------- REGISTER ----------------
Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
  required String role,
  String? phone,
  String? companyName,
  String? companyReg,
  String? companyDis,
  File? companyLogo,
}) async {
  final uri = Uri.parse('$baseUrl/register');
  var request = http.MultipartRequest('POST', uri);

  request.fields['name'] = name;
  request.fields['email'] = email;
  request.fields['password'] = password;
  request.fields['role'] = role;

  if (role == 'student' && phone != null) request.fields['phone'] = phone;

  if (role == 'company') {
    if (companyName != null) request.fields['companyName'] = companyName;
    if (companyReg != null) request.fields['companyReg'] = companyReg;
    if (companyDis != null) request.fields['companyDis'] = companyDis;
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

  debugPrint('--- REGISTER REQUEST ---');
  request.fields.forEach((k, v) => debugPrint('$k: $v'));
  if (request.files.isNotEmpty) debugPrint('Files: ${request.files.map((f) => f.filename).join(', ')}');

  try {
    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);
    final data = _processResponse(res);

    // Save session if accessToken exists
    if (data.containsKey('accessToken')) {
      await saveUserSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        role: data['user']['role'],
        userId: data['user']['id'],
      );
    }

    debugPrint('--- REGISTER RESPONSE ---');
    debugPrint(res.body);
    debugPrint('-------------------------');

    // ----------------- CALL /profile FOR COMPANY -----------------
    if (role == 'company') {
      final profileUri = Uri.parse('http://10.0.2.2:4000/api/company/profile');
      var profileRequest = http.MultipartRequest('POST', profileUri);

      // Add required fields
      profileRequest.fields['companyId'] = data['user']['id']; // from register response
      if (companyName != null) profileRequest.fields['companyName'] = companyName;
      if (email.isNotEmpty) profileRequest.fields['email'] = email;
      if (companyReg != null) profileRequest.fields['companyReg'] = companyReg;
      if (companyDis != null) profileRequest.fields['companyDis'] = companyDis;
      profileRequest.fields['role'] = role;
      profileRequest.fields['password'] = password;

      // Add logo if exists
      if (companyLogo != null) {
        final mimeType = lookupMimeType(companyLogo.path) ?? 'image/jpeg';
        final mimeSplit = mimeType.split('/');
        final file = await http.MultipartFile.fromPath(
          'companyLogo',
          companyLogo.path,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        );
        profileRequest.files.add(file);
      }

      // Send profile request
      final streamedProfileResponse = await profileRequest.send();
      final profileRes = await http.Response.fromStream(streamedProfileResponse);
      debugPrint('--- PROFILE RESPONSE ---');
      debugPrint(profileRes.body);
    }

    return data;
  } catch (e) {
    debugPrint('❌ REGISTER ERROR: $e');
    rethrow;
  }
}


  // ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint("SERVER RESPONSE: ${res.body}");

      final data = _processResponse(res);

      if (data.containsKey('accessToken')) {
        await saveUserSession(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          role: data['user']['role'],
          userId: data['user']['id'],
        );
      }

      return data;
    } catch (e) {
      debugPrint('❌ LOGIN ERROR: $e');
      rethrow;
    }
  }

  // ---------------- FORGOT PASSWORD ----------------
  Future<Map<String, dynamic>> forgot(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _processResponse(res);
    } catch (e) {
      debugPrint('❌ FORGOT PASSWORD ERROR: $e');
      rethrow;
    }
  }

  // ---------------- RESET PASSWORD ----------------
  Future<Map<String, dynamic>> reset(String token, String id, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'id': id, 'newPassword': newPassword}),
      );
      return _processResponse(res);
    } catch (e) {
      debugPrint('❌ RESET PASSWORD ERROR: $e');
      rethrow;
    }
  }

  // ---------------- RESPONSE HANDLER ----------------
  Map<String, dynamic> _processResponse(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Error ${res.statusCode}');
  }

  // ---------------- SAVE SESSION ----------------
  Future<void> saveUserSession({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
  }) async {
    try {
      await storage.write(key: 'accessToken', value: accessToken);
      await storage.write(key: 'refreshToken', value: refreshToken);
      await storage.write(key: 'role', value: role);
      await storage.write(key: 'userId', value: userId);
      debugPrint("🔐 User session saved. UserId: $userId, Role: $role");
    } catch (e) {
      debugPrint("❌ Failed to save session: $e");
    }
  }

  // ---------------- RESTORE SESSION ----------------
  Future<Map<String, String>?> restoreUserSession() async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final refreshToken = await storage.read(key: 'refreshToken');
      final role = await storage.read(key: 'role');
      final userId = await storage.read(key: 'userId');

      if (accessToken != null && refreshToken != null && role != null && userId != null) {
        debugPrint("🔄 Restored user session. UserId: $userId, Role: $role");
        return {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'role': role,
          'userId': userId,
        };
      }
      return null;
    } catch (e) {
      debugPrint("❌ Failed to restore session: $e");
      return null;
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
  try {
    // Only clear session-related keys
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'role');
    await storage.delete(key: 'userId');

    // Keep savedEmail and savedPassword intact for autofill
    debugPrint("🔓 User logged out, session cleared. Saved credentials kept for autofill.");
  } catch (e) {
    debugPrint("❌ Failed to logout: $e");
  }
}


  // ---------------- GETTERS ----------------
  Future<String?> getRole() async => await storage.read(key: 'role');
  Future<String?> getUserId() async => await storage.read(key: 'userId');

  Future<String?> getAccessToken() async => await storage.read(key: 'accessToken');
  Future<String?> getRefreshToken() async => await storage.read(key: 'refreshToken');

  // ---------------- REMEMBER ME ----------------
  Future<void> saveLoginCredentials(String email, String password) async {
  try {
    await storage.write(key: 'savedEmail', value: email);
    await storage.write(key: 'savedPassword', value: password);
    debugPrint("💾 Saved login credentials: $email / $password");
  } catch (e) {
    debugPrint("❌ Failed to save credentials: $e");
  }
}


  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await storage.read(key: 'savedEmail');
      final password = await storage.read(key: 'savedPassword');
      if (email != null && password != null) return {"email": email, "password": password};
      return null;
    } catch (e) {
      debugPrint("❌ Failed to load credentials: $e");
      return null;
    }
  }

  Future<void> clearSavedCredentials() async {
    try {
      await storage.delete(key: 'savedEmail');
      await storage.delete(key: 'savedPassword');
      debugPrint("🗑️ Cleared saved credentials.");
    } catch (e) {
      debugPrint("❌ Failed to clear credentials: $e");
    }
  }
}
