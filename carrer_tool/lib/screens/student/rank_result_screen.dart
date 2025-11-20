import 'package:flutter/material.dart';
import '../../services/rank_service.dart';
import 'user_profile_screen.dart';

class RankResultScreen extends StatefulWidget {
  final String userId;
  final String companyName;
  final String jobRole;
  final String jobPostId;
  final Map<String, int> weights;

  const RankResultScreen({
    super.key,
    required this.userId,
    required this.companyName,
    required this.jobRole,
    required this.jobPostId,
    required this.weights,
  });

  @override
  State<RankResultScreen> createState() => _RankResultScreenState();
}

class _RankResultScreenState extends State<RankResultScreen> {
  late Future<List<RankUser>> _leaderboardFuture;
  final ScrollController _scrollController = ScrollController();

  String selectedYear = "Any Year";
  List<String> years = ["Any Year", "1st Year", "2nd Year", "3rd Year", "4th Year"];

  String selectedUniversity = "All Universities";
  List<String> universities = ["All Universities", "UoM", "UCSC", "SLIIT", "UoK", "UoJ"];

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = RankService().fetchLeaderboard(
      userId: widget.userId,
      jobPostId: widget.jobPostId,
      weights: widget.weights,
    );
  }

  int? _yearFilter() {
    if (selectedYear == "Any Year") return null;
    return int.tryParse(selectedYear[0]);
  }

  Color getTopColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade400;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.white;
    }
  }

  Widget getRankCircle(int rank) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rank <= 3 ? getTopColor(rank) : Colors.blue.shade700,
      ),
      alignment: Alignment.center,
      child: Text(
        "$rank",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: rank <= 3 ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Colors.blue.shade700;
    final Color grayBorder = Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.companyName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            Text(
              widget.jobRole,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<RankUser>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<RankUser> leaderboard = snapshot.data!;
          leaderboard.sort((a, b) => b.score.compareTo(a.score));

          final yearFilter = _yearFilter();
          if (yearFilter != null) {
            leaderboard = leaderboard.where((u) => u.year == yearFilter).toList();
          }

          if (selectedUniversity != "All Universities") {
            leaderboard =
                leaderboard.where((u) => u.university == selectedUniversity).toList();
          }

          if (searchQuery.isNotEmpty) {
            leaderboard = leaderboard
                .where((u) => u.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
          }

          int rank = 1;
          leaderboard = leaderboard.map((u) => u.copyWith(rank: rank++)).toList();

          return Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search student...",
                    prefixIcon: const Icon(Icons.search, size: 22),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: grayBorder),
                    ),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),

              // Filters Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Year",
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: grayBorder),
                          ),
                        ),
                        value: selectedYear,
                        items: years
                            .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedYear = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "University",
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: grayBorder),
                          ),
                        ),
                        value: selectedUniversity,
                        items: universities
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedUniversity = val!),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Top Rankings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Leaderboard
              Expanded(
                child: leaderboard.isEmpty
                    ? Center(
                        child: Text(
                          "No students found for this role.",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = leaderboard[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(
                                        userId: user.userId,
                                        jobPostId: widget.jobPostId,
                                      )),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: user.rank <= 3
                                    ? getTopColor(user.rank).withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: user.rank <= 3 ? getTopColor(user.rank) : grayBorder,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  getRankCircle(user.rank),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${user.university} • Year ${user.year} • Projects: ${user.projects}",
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${user.score}",
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
