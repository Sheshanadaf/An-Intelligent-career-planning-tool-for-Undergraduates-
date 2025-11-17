import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UserApi {
  final String baseUrl = "http://10.0.2.2:4000/api/student";

  /// Fetch user profile
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/profile/$userId");
      print("🔍 GET URL: $url");

      final resp = await http.get(url);

      print("📦 Response status: ${resp.statusCode}");
      print("📦 Response body: ${resp.body}");

      if (resp.statusCode == 200) {
        print("✅ GET /profile/$userId success");
        return json.decode(resp.body) as Map<String, dynamic>;
      } else {
        print("❌ GET failed: ${resp.statusCode} ${resp.reasonPhrase}");
        return null;
      }
    } catch (e, st) {
      print("❌ Error in getUser: $e\n$st");
      return null;
    }
  }

  /// Update profile (text + image)
  Future<Map<String, dynamic>?> updateProfile({
    required String userId,
    required String name,
    required String bio,
    required String location,
    File? imageFile,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/profileheader");
      print("🔍 PUT URL: $url");

      final request = http.MultipartRequest('PUT', url);

      // Add text fields
      request.fields['userId'] = userId;
      request.fields['name'] = name;
      request.fields['bio'] = bio;
      request.fields['location'] = location;

      print("📝 Request fields:");
      request.fields.forEach((key, value) {
        print(" - $key: $value");
      });

      // Add image file if exists
      if (imageFile != null) {
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        final mimeSplit = mimeType.split('/');
        print("📷 Adding image file: ${imageFile.path}, mimeType: $mimeType");

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType(mimeSplit[0], mimeSplit[1]),
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      print("📦 Response status: ${resp.statusCode}");
      print("📦 Response body: ${resp.body}");

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        print("✅ UPDATE profile success");
        return json.decode(resp.body) as Map<String, dynamic>;
      } else {
        print("❌ Update failed: ${resp.statusCode} ${resp.reasonPhrase}");
        return null;
      }
    } catch (e, st) {
      print("❌ Error in updateProfile: $e\n$st");
      return null;
    }
  }
}
