import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/university_ranking_api.dart';

class UniversityRankingScreenBody extends StatefulWidget {
  final String userId;
  const UniversityRankingScreenBody({super.key, required this.userId});

  @override
  State<UniversityRankingScreenBody> createState() =>
      _UniversityRankingScreenBodyState();
}

class _UniversityRankingScreenBodyState
    extends State<UniversityRankingScreenBody> with TickerProviderStateMixin {
  final UniversityRankingService _service = UniversityRankingService();
  List<Map<String, dynamic>> _rankings = [];
  bool _loading = true;

  bool get isAdmin => widget.userId == "691ee6411dce7243c42217fd";

  bool _gradingExpanded = false;
  late final AnimationController _gradingController;
  late final Animation<double> _gradingAnimation;

  late final AnimationController _listAnimationController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _gradingController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _gradingAnimation =
        CurvedAnimation(parent: _gradingController, curve: Curves.easeInOut);

    _listAnimationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fetchRankings();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _gradingController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRankings() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchRankings();
      setState(() {
        _rankings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
      _listAnimationController.forward();
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _toggleGradingCard() {
    setState(() => _gradingExpanded = !_gradingExpanded);
    _gradingExpanded ? _gradingController.forward() : _gradingController.reverse();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst("Exception: ", "❌ ")),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError("Could not open the link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isAdmin
              ? _buildAdminView()
              : _buildStudentView(),
    );
  }

  // ---------------- Glass-style Container ----------------
  Widget _glassContainer({required Widget child, double borderRadius = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }

  // ------------------- Admin View -------------------
  Widget _buildAdminView() {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _rankings.length,
          itemBuilder: (context, index) =>
              _buildAnimatedLeaderboardCard(_rankings[index], index),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _showAddUniversityDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add University"),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ------------------- Student View -------------------
  Widget _buildStudentView() {
    final filteredRankings = _rankings
        .where((uni) =>
            uni['name'].toString().toLowerCase().contains(_searchQuery))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- Top Container ----------------
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 136, 229),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------- Grading Card ----------------
                GestureDetector(
                  onTap: _toggleGradingCard,
                  child: _glassContainer(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "How the grading system works",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          AnimatedRotation(
                            turns: _gradingExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(Icons.expand_more, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                SizeTransition(
                  sizeFactor: _gradingAnimation,
                  axisAlignment: -1,
                  child: _glassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _gradingRow("Total Score", "Total Score = R + C + B + P",
                              Colors.white, Icons.calculate),
                          const Divider(color: Colors.white30),
                          _gradingRow(
                              "R - University Rank Score",
                              "R = ((MaxRank - UniRank) / (MaxRank - 1)) × W1",
                              const Color.fromARGB(255, 255, 255, 255),
                              Icons.school),
                          _gradingRow(
                              "C - Degree Class Score",
                              "1st class = 1 Marks\n2nd upper = 0.75 Marks\n2nd lower = 0.5 Marks\nGeneral pass = 0.25 Marks\nFail = 0 Marks\nC = Marks x W2",
                              const Color.fromARGB(255, 255, 255, 255),
                              Icons.star),
                          _gradingRow(
                              "B - Certification / Badge Score",
                              "B = (EarnedCertifiMarks / TotalCertifiMarks) × W3",
                              const Color.fromARGB(255, 255, 255, 255),
                              Icons.badge),
                          _gradingRow(
                              "P - Project Score",
                              "P = (EarnedProjeMarks / TotalProjMarks) x W4",
                              const Color.fromARGB(255, 255, 255, 255),
                              Icons.build),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ---------------- Source Bar ----------------
                _glassContainer(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                    text: "Source: ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white)),
                                TextSpan(
                                    text: "XYZ University Rankings 2025",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, color: Colors.white),
                          onPressed: () =>
                              _launchURL("https://www.example.com/uni-ranking"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ---------------- Search Box ----------------
                _glassContainer(
                  borderRadius: 32,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search universities...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- University Leaderboard ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "University Leaderboard",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue.shade900),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: filteredRankings
                .asMap()
                .entries
                .map((entry) =>
                    _buildAnimatedLeaderboardCard(entry.value, entry.key))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- Animated Card ----------------
  Widget _buildAnimatedLeaderboardCard(Map<String, dynamic> uni, int index) {
    final Animation<double> animation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut),
    );

    Color rankColor;
    switch (index) {
      case 0:
        rankColor = Colors.amber.shade700;
        break;
      case 1:
        rankColor = Colors.grey.shade400;
        break;
      case 2:
        rankColor = Colors.brown.shade400;
        break;
      default:
        rankColor = Colors.blue.shade600;
    }

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [rankColor.withOpacity(0.9), rankColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: rankColor.withOpacity(0.4), blurRadius: 8)
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  uni['rank'].toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),

              // University Name + Admin Actions
              Expanded(
                child: Text(
                  uni['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87),
                ),
              ),

              // Admin: Edit & Delete Buttons
              if (isAdmin)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      tooltip: "Edit University",
                      onPressed: () => _showEditUniversityDialog(uni),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: "Delete University",
                      onPressed: () => _deleteUniversity(uni['_id']),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Grading Row ----------------
  Widget _gradingRow(String title, String description, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(fontSize: 13, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- Admin Dialogs -------------------
  void _showEditUniversityDialog(Map<String, dynamic> uni) {
    final TextEditingController nameController = TextEditingController(text: uni['name']);
    final TextEditingController rankController = TextEditingController(text: uni['rank'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit University"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "University Name"),
            ),
            TextField(
              controller: rankController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Rank"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final rank = int.tryParse(rankController.text.trim()) ?? 0;

              if (name.isEmpty || rank <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter valid name and rank")),
                );
                return;
              }

              try {
                await _service.updateRanking(uni['_id'], name, rank);
                Navigator.pop(ctx);
                await _fetchRankings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("University updated successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUniversity(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this university?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteRanking(id);
      await _fetchRankings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("University deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showAddUniversityDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _rankController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add University"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "University Name"),
            ),
            TextField(
              controller: _rankController,
              decoration: const InputDecoration(labelText: "Rank"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = _nameController.text.trim();
              final rank = int.tryParse(_rankController.text.trim());

              if (name.isEmpty || rank == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              try {
                await _service.addRanking(name, rank);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("University added successfully")),
                );
                Navigator.pop(ctx);
                await _fetchRankings();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
