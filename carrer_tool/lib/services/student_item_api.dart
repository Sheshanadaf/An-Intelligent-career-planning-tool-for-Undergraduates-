import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentItemApi {
  final String baseUrl = "http://10.0.2.2:4000/api/student";

  // Delete an item
  Future<bool> deleteItem(String userId, String type, String itemId) async {
    try {
      final url = Uri.parse("$baseUrl/$type/$itemId?userId=$userId");
      final resp = await http.delete(url);
      return resp.statusCode == 200;
    } catch (e) {
      print("Delete Error: $e");
      return false;
    }
  }

  // Update an item
  Future<bool> updateItem(String userId, String type, String itemId, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse("$baseUrl/$type/$itemId?userId=$userId");
      final resp = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );
      return resp.statusCode == 200;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }
}
