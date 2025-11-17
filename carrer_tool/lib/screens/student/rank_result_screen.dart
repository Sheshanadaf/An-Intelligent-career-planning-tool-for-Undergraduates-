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
    return CircleAvatar(
      radius: 20,
      backgroundColor: getTopColor(rank),
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
    final Color primaryBlue = Colors.blue.shade600;
    final Color lightBlue = Colors.blue.shade50;
    final Color grayBorder = Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Leaderboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
            leaderboard = leaderboard
                .where((u) => u.university == selectedUniversity)
                .toList();
          }

          if (searchQuery.isNotEmpty) {
            leaderboard = leaderboard
                .where((u) => u.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
          }

          int rank = 1;
          leaderboard = leaderboard.map((u) => u.copyWith(rank: rank++)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company & Job Role Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.companyName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work_outline,
                            color: Colors.white70, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.jobRole,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🔍 Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search student...",
                      prefixIcon: const Icon(Icons.search, size: 22),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: grayBorder),
                      ),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
              ),

              // 🎓 Year & University Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Year",
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: grayBorder),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        initialValue: selectedYear,
                        items: years
                            .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (value) => setState(() => selectedYear = value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "University",
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: grayBorder),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        initialValue: selectedUniversity,
                        items: universities
                            .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedUniversity = value!),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "Top Rankings",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),

              // 🏆 Leaderboard
              Expanded(
                child: ListView.builder(
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
                        decoration: BoxDecoration(
                          color: user.rank <= 3
                              ? getTopColor(user.rank).withOpacity(0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: user.rank <= 3
                                ? getTopColor(user.rank)
                                : grayBorder,
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: getRankCircle(user.rank),
                          title: Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            "${user.university} • Year ${user.year} • Projects: ${user.projects}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            "${user.score}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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
