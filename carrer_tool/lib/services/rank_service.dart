import 'dart:convert';
import 'package:http/http.dart' as http;

class RankUser {
  final String userId;
  final String name;
  final double score;
  final int projects;
  final String university;
  final int year;
  final int rank;

  RankUser({
    required this.userId,
    required this.name,
    required this.score,
    required this.projects,
    required this.university,
    required this.year,
    this.rank = 0,
  });

  RankUser copyWith({int? rank}) => RankUser(
        userId: userId,
        name: name,
        score: score,
        projects: projects,
        university: university,
        year: year,
        rank: rank ?? this.rank,
      );

  factory RankUser.fromJson(Map<String, dynamic> json) {
    return RankUser(
      userId: json['userId'],
      name: json['name'],
      score: (json['score'] as num).toDouble(),
      projects: json['projects'],
      university: json['university'],
      year: json['year'],
    );
  }
}

class RankService {
  final String baseUrl = "http://10.0.2.2:4000/api/scalculate";

  Future<List<RankUser>> fetchLeaderboard({
    required String userId,
    required String jobPostId,
    required Map<String, int> weights,
  }) async {
    print("📌 fetchLeaderboard called with:");
    print("UserId: $userId");
    print("JobPostId: $jobPostId");
    print("Weights: $weights");

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jobPostId': jobPostId,
        'weights': weights,
      }),
    );

    print("📌 Response status: ${res.statusCode}");
    print("📌 Response body: ${res.body}");

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => RankUser.fromJson(e)).toList();
    } else {
      final Map<String, dynamic> err = jsonDecode(res.body);
      throw Exception(err['message'] ?? 'Unexpected error');
    }
  }
}



      //RankUser(userId: "u101", name: "Tharindu", score: 98, projects: 8, university: "UoJ", year: 1),
      //RankUser(userId: "u102", name: "Ishara", score: 92, projects: 7, university: "UCSC", year: 3),
      //RankUser(userId: "690ac177975031f6354fe32d", name: "Kasun", score: 89, projects: 6, university: "SLIIT", year: 3),
      //RankUser(userId: "u104", name: "Nimesh", score: 85, projects: 6, university: "UoK", year: 2),
      //RankUser(userId: "u201", name: "sheshan", score: 50, projects: 5, university: "UoJ", year: 1),
      //RankUser(userId: "690ce41a9086b856f32ff6e0", name: "You", score: 82, projects: 5, university: "UoJ", year: 2),

