import 'package:flutter/material.dart';
import 'services/leaderboard_api.dart';
import 'user_detail_screen.dart'; // Create this screen for individual user view

class ViewRankScreen extends StatefulWidget {
  final String jobRole;
  final String companyId;
  final String jobPostId;
  final Map<String, dynamic> weights; // ✅ Change from String to Map
 

  const ViewRankScreen({
    super.key,
    required this.jobRole,
    required this.companyId, 
    required this.jobPostId, 
    required this.weights,
  });

  @override
  State<ViewRankScreen> createState() => _ViewRankScreenState();
}

class _ViewRankScreenState extends State<ViewRankScreen> {
  final LeaderboardApi api = LeaderboardApi();
  late Future<List<Map<String, dynamic>>> leaderboardFuture;

  @override
  void initState() {
    super.initState();
    leaderboardFuture = api.fetchLeaderboard(
      jobPostId: widget.jobPostId,
      weights:widget.weights,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leaderboard - ${widget.jobRole}")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error fetching leaderboard: ${snapshot.error}"),
            );
          }

          final leaderboard = snapshot.data ?? [];

          if (leaderboard.isEmpty) {
            return const Center(child: Text("No users found for this role."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final user = leaderboard[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    child: Text("${index + 1}"),
                  ),
                  title: Text(
                    user['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "University: ${user['university']}\nYear: ${user['year']}\nProjects: ${user['projects']}\nScore: ${user['score']}"),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailScreen(
                            userId: user['userId'],
                            jobPostId:widget.jobPostId,
                          ),
                        ),
                      );
                    },
                    child: const Text("View"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
