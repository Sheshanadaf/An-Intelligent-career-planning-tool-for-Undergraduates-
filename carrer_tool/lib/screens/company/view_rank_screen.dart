import 'package:flutter/material.dart';
import 'services/leaderboard_api.dart';
import 'user_detail_screen.dart';

class ViewRankScreen extends StatefulWidget {
  final String jobRole;
  final String companyName;
  final String jobPostId;
  final Map<String, dynamic> weights;

  const ViewRankScreen({
    super.key,
    required this.jobRole,
    required this.companyName,
    required this.jobPostId,
    required this.weights,
  });

  @override
  State<ViewRankScreen> createState() => _ViewRankScreenState();
}

class _ViewRankScreenState extends State<ViewRankScreen> {
  final LeaderboardApi api = LeaderboardApi();
  late Future<List<Map<String, dynamic>>> leaderboardFuture;

  String searchQuery = "";
  String selectedYear = "Any Year";
  List<String> years = ["Any Year", "1", "2", "3", "4"];
  String selectedUniversity = "All Universities";
  List<String> universities = ["All Universities", "UoM", "UCSC", "SLIIT", "UoK", "UoJ"];

  @override
  void initState() {
    super.initState();
    leaderboardFuture = api.fetchLeaderboard(
      jobPostId: widget.jobPostId,
      weights: widget.weights,
    );
  }

  // Modern gradient colors for top 3 ranks
  LinearGradient? getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFC107)], // Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFFB0B0B0)], // Silver
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFB87333)], // Bronze
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return null;
    }
  }

  Color getRankTextColor(int rank) {
    return rank <= 3 ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final grayBorder = Colors.grey.shade300;
    final primaryBlue = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.jobRole,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue, // ✅ AppBar blue
        foregroundColor: Colors.white, // ✅ Back button white
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
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

          List<Map<String, dynamic>> leaderboard = snapshot.data ?? [];

          // Filtering
          if (selectedYear != "Any Year") {
            leaderboard = leaderboard
                .where((u) => u['year'].toString() == selectedYear)
                .toList();
          }
          if (selectedUniversity != "All Universities") {
            leaderboard =
                leaderboard.where((u) => u['university'] == selectedUniversity).toList();
          }
          if (searchQuery.isNotEmpty) {
            leaderboard = leaderboard
                .where((u) =>
                    u['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
          }

          // Sort by score descending
          leaderboard.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search student...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: grayBorder),
                        ),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "Year",
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: grayBorder),
                              ),
                            ),
                            value: selectedYear,
                            items: years
                                .map((y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(y),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedYear = val ?? "Any Year"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "University",
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: grayBorder),
                              ),
                            ),
                            value: selectedUniversity,
                            items: universities
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedUniversity = val ?? "All Universities"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Leaderboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: leaderboard.isEmpty
                    ? Center(
                        child: Text(
                          "No students found for this role.",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = leaderboard[index];
                          final rank = index + 1;
                          final gradient = getRankGradient(rank);
                          final isTop3 = index < 3;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserDetailScreen(
                                      userId: user['userId'],
                                      jobPostId: widget.jobPostId,
                                    ),
                                  ));
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                                border: Border.all(color: grayBorder, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  // Rank Circle with gradient for top 3
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: gradient,
                                      color: gradient == null ? Colors.blue.shade700 : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "$rank",
                                      style: TextStyle(
                                        color: getRankTextColor(rank),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'] ?? "Unknown",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${user['university']} • Year ${user['year']} • Projects: ${user['projects']}",
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${user['score']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
