import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class StudentOnboardingProvider extends ChangeNotifier {
  final storage = const FlutterSecureStorage();
  final String baseUrl = "http://10.0.2.2:4000/api";

  Map<String, dynamic> studentProfile = {
    "name": "",
    "bio": "",
    "location": "",
    "imageUrl": "",
    "imageFile": null,
    "education": [],
    "skills": [],
    "licenses": [],
    "projects": [],
    "volunteering": [],
  };

  String selectedPage = "home";

  // ================== REMOVE METHODS ==================
  void removeEducation(int index) {
    studentProfile["education"].removeAt(index);
    notifyListeners();
  }

  void removeProject(int index) {
    studentProfile["projects"].removeAt(index);
    notifyListeners();
  }

  void removeLicense(int index) {
    studentProfile["licenses"].removeAt(index);
    notifyListeners();
  }

  void removeVolunteering(int index) {
    studentProfile["volunteering"].removeAt(index);
    notifyListeners();
  }

  void setSelectedPage(String page) {
    selectedPage = page;
    notifyListeners();
  }

  // ================== SET METHODS ==================
  void setPersonalInfo({
    required String name,
    required String bio,
    required String location,
    File? imageFile,
  }) {
    studentProfile["name"] = name;
    studentProfile["bio"] = bio;
    studentProfile["location"] = location;
    studentProfile["imageFile"] = imageFile;
    notifyListeners();
  }

  void setEducation(List<Map<String, dynamic>> education) {
    studentProfile["education"] = education;
    notifyListeners();
  }

  void setSkills(List<String> skills) {
    studentProfile["skills"] = skills;
    notifyListeners();
  }

  void setLicenses(List<Map<String, dynamic>> licenses) {
    studentProfile["licenses"] = licenses;
    notifyListeners();
  }

  void setProjects(List<Map<String, dynamic>> projects) {
    studentProfile["projects"] = projects;
    notifyListeners();
  }

  void setVolunteering(List<Map<String, dynamic>> volunteering) {
    studentProfile["volunteering"] = volunteering;
    notifyListeners();
  }

  // ================== ONBOARDING HELPER GETTERS ==================
  Map<String, dynamic> get personalInfo => {
        "name": studentProfile["name"],
        "bio": studentProfile["bio"],
        "location": studentProfile["location"],
        "imageFile": studentProfile["imageFile"],
      };

  List<Map<String, dynamic>> get education =>
      List<Map<String, dynamic>>.from(studentProfile["education"]);

  List<String> get skills => List<String>.from(studentProfile["skills"]);

  // ================== FETCH PROFILE ==================
  Future<void> fetchProfile(String userId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/student/profile/$userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        studentProfile = {
          "name": data["name"] ?? "",
          "bio": data["bio"] ?? "",
          "location": data["location"] ?? "",
          "imageUrl": data["imageUrl"] ?? "",
          "imageFile": null,
          "education": List<Map<String, dynamic>>.from(data["education"] ?? []),
          "skills": List<String>.from(data["skills"] ?? []),
          "licenses": List<Map<String, dynamic>>.from(data["licenses"] ?? []),
          "projects": List<Map<String, dynamic>>.from(data["projects"] ?? []),
          "volunteering": List<Map<String, dynamic>>.from(data["volunteering"] ?? []),
        };
        notifyListeners();
      } else {
        debugPrint("❌ Failed to fetch profile with status ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
    }
  }

  // ================== UPDATE PROFILE ==================
  Future<bool> updateProfile() async {
    const String url = "http://10.0.2.2:4000/api/student/profile/update";
    final token = await storage.read(key: 'accessToken');
    final userId = await storage.read(key: 'userId');

    if (token == null || userId == null) return false;

    try {
      final request = http.MultipartRequest('PUT', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['userId'] = userId;
      request.fields['name'] = studentProfile["name"];
      request.fields['bio'] = studentProfile["bio"];
      request.fields['location'] = studentProfile["location"];
      request.fields['education'] = jsonEncode(studentProfile["education"]);
      request.fields['skills'] = jsonEncode(studentProfile["skills"]);
      request.fields['licenses'] = jsonEncode(studentProfile["licenses"]);
      request.fields['projects'] = jsonEncode(studentProfile["projects"]);
      request.fields['volunteering'] = jsonEncode(studentProfile["volunteering"]);

      if (studentProfile["imageFile"] != null) {
        final file = studentProfile["imageFile"] as File;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        studentProfile["imageUrl"] =
            data['profile']['imageUrl'] ?? studentProfile["imageUrl"];
        notifyListeners();
        return true;
      } else {
        debugPrint("❌ Failed with status ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating profile: $e");
      return false;
    }
  }

  // ================== SUBMIT PROFILE ==================
  Future<bool> submitProfile() async {
    const String url = "http://10.0.2.2:4000/api/student/profile";
    final token = await storage.read(key: 'accessToken');
    final userId = await storage.read(key: 'userId');

    if (token == null || userId == null) return false;

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['userId'] = userId;
      request.fields['name'] = studentProfile["name"];
      request.fields['bio'] = studentProfile["bio"];
      request.fields['location'] = studentProfile["location"];
      request.fields['education'] = jsonEncode(studentProfile["education"]);
      request.fields['skills'] = jsonEncode(studentProfile["skills"]);
      request.fields['licenses'] = jsonEncode(studentProfile["licenses"]);
      request.fields['projects'] = jsonEncode(studentProfile["projects"]);
      request.fields['volunteering'] = jsonEncode(studentProfile["volunteering"]);

      if (studentProfile["imageFile"] != null) {
        final file = studentProfile["imageFile"] as File;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        studentProfile["imageUrl"] = data['profile']['imageUrl'] ?? "";
        notifyListeners();
        return true;
      } else {
        debugPrint("❌ Failed with status ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error submitting profile: $e");
      return false;
    }
  }

  // ================== CLEAR PROFILE ==================
  void clearProfile() {
    studentProfile = {
      "name": "",
      "bio": "",
      "location": "",
      "imageUrl": "",
      "imageFile": null,
      "education": [],
      "skills": [],
      "licenses": [],
      "projects": [],
      "volunteering": [],
    };
    selectedPage = "home";
    notifyListeners();
  }
}
