import 'dart:convert';
import 'package:http/http.dart' as http;

class UniversityRankingService {
  final String baseUrl = "http://10.0.2.2:4000/api/university-rankings";

  // ✅ Fetch all university rankings
  Future<List<dynamic>> fetchRankings() async {
    final res = await http.get(Uri.parse(baseUrl));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = _extractErrorMessage(res);
      throw Exception(error);
    }
  }

  // ✅ Add new ranking
  Future<void> addRanking(String name, int rank) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'rank': rank}),
    );

    if (res.statusCode != 201) {
      final error = _extractErrorMessage(res);
      throw Exception(error);
    }
  }

  // ✅ Update existing ranking
  Future<void> updateRanking(String id, String name, int rank) async {
    final res = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'rank': rank}),
    );

    if (res.statusCode != 200) {
      final error = _extractErrorMessage(res);
      throw Exception(error);
    }
  }

  // ✅ Delete ranking
  Future<void> deleteRanking(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/$id'));

    if (res.statusCode != 200) {
      final error = _extractErrorMessage(res);
      throw Exception(error);
    }
  }

  // 🧠 Helper: extract backend error message safely
  String _extractErrorMessage(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Unexpected error: ${res.statusCode}';
    } catch (_) {
      return 'Unexpected server error (${res.statusCode})';
    }
  }
}
