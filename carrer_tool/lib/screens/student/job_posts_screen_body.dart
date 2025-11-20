import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/job_post_api.dart';

class JobPostsScreenBody extends StatefulWidget {
  final String userId;
  const JobPostsScreenBody({super.key, required this.userId});

  @override
  State<JobPostsScreenBody> createState() => _JobPostsScreenBodyState();
}

class _JobPostsScreenBodyState extends State<JobPostsScreenBody>
    with SingleTickerProviderStateMixin {
  final JobPostsApi api = JobPostsApi();
  late TabController _tabController;

  List<dynamic> allJobs = [];
  List<dynamic> recommendedJobs = [];
  List<dynamic> addedJobs = [];
  List<dynamic> displayedJobs = [];

  bool isLoading = true;
  String searchCompany = "";
  String searchRole = "";

  Map<String, bool> entryExpandedMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadJobs();
    });
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => isLoading = true);
    try {
      if (_tabController.index == 0) {
        allJobs = await api.fetchAllJobs();
        displayedJobs = allJobs;
      } else if (_tabController.index == 1) {
        recommendedJobs = [];
        displayedJobs = recommendedJobs;
      } else {
        addedJobs = await api.fetchAddedJobs(widget.userId);
        displayedJobs = addedJobs;
      }
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
    }
    setState(() => isLoading = false);
  }

  void _filterJobs() {
    final list = _tabController.index == 0
        ? allJobs
        : _tabController.index == 1
            ? recommendedJobs
            : addedJobs;

    setState(() {
      displayedJobs = list.where((job) {
        final companyMatch = job['companyName']
            .toString()
            .toLowerCase()
            .contains(searchCompany.toLowerCase());
        final roleMatch = job['jobRole']
            .toString()
            .toLowerCase()
            .contains(searchRole.toLowerCase());
        return companyMatch && roleMatch;
      }).toList();
    });
  }

  Widget _buildJobCard(Map<String, dynamic> job,
      {bool isAddedTab = false, required int index}) {
    final String jobKey = job['_id']?.toString() ?? 'idx_$index';
    final bool isExpanded = entryExpandedMap[jobKey] ?? false;

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12), // smaller height
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color.fromARGB(255, 187, 187, 187).withOpacity(1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isExpanded ? 0.12 : 0.08),
                blurRadius: isExpanded ? 14 : 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: ValueKey(jobKey),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) {
                setState(() => entryExpandedMap[jobKey] = val);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // reduced padding
              expandedCrossAxisAlignment: CrossAxisAlignment.start,

              // BLACK ROTATING ARROW
              trailing: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 28),
              ),

              title: Text(
                job['jobRole'] ?? "Unknown Role",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
              ),

              subtitle: Text(
                job['companyName'] ?? "Unknown Company",
                style: const TextStyle(color: Colors.black87),
              ),

              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: job['companyLogo'] != null
                    ? NetworkImage(job['companyLogo'])
                    : null,
                child: job['companyLogo'] == null
                    ? const Icon(Icons.business, color: Colors.black)
                    : null,
              ),

              children: [
                _buildDetailRow("Description", job['description']),
                _buildDetailRow(
                    "Skills",
                    job['skills'] is List
                        ? (job['skills'] as List).join(", ")
                        : job['skills']),
                _buildDetailRow("Certifications", job['certifications']),
                _buildDetailRow("Details", job['details']),

                // HORIZONTAL WEIGHT BAR
                if (job['weights'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildWeightBar(job['weights']), // slimmer bar
                  ),

                const SizedBox(height: 6),

                // ACTION BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAddedTab)
                      OutlinedButton.icon(
                        onPressed: () async {
                          bool success = await api.removeJobFromUser(
                              widget.userId, job['_id']);
                          if (success) {
                            setState(() {
                              addedJobs.removeWhere((j) => j['_id'] == job['_id']);
                              displayedJobs = List.from(addedJobs);
                            });
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(12),
                            content: Text(success
                                ? "🗑 Removed '${job['jobRole']}'"
                                : "❌ Operation failed."),
                          ));
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.red.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 14),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          bool success =
                              await api.addJobToUser(widget.userId, job['_id']);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(12),
                            content: Text(success
                                ? "Added '${job['jobRole']}'"
                                : "Operation failed."),
                          ));
                        },
                        icon: Icon(Icons.add, color: Colors.blue.shade600),
                        label: Text(
                          "Add to My Jobs",
                          style: TextStyle(color: Colors.blue.shade600),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.blue.shade600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 14),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, (1 - val) * 10),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          cardContent,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title:",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          textAlign: TextAlign.justify,   // ← FULL JUSTIFY
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            height: 1.35,                 // ← Improved readability
          ),
        ),
      ],
    ),
  );
}


  Widget _buildWeightBar(Map<String, dynamic> weights) {
    final List<Map<String, dynamic>> segments = [
      {"label": "Uni.", "value": weights['university'] ?? 0, "color": const Color.fromARGB(255, 0, 0, 128)},
      {"label": "GPA", "value": weights['gpa'] ?? 0, "color": const Color.fromARGB(255, 65, 105, 225)},
      {"label": "Certi.", "value": weights['certifications'] ?? 0, "color": const Color.fromARGB(255, 35, 206, 235)},
      {"label": "Proj.", "value": weights['projects'] ?? 0, "color": const Color.fromARGB(255, 0, 128, 128)},
    ];

    final filtered = segments.where((s) => (s['value'] ?? 0) > 0).toList();
    final total = filtered.fold<num>(0, (sum, s) => sum + (s['value'] ?? 0));

    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 20, // slimmer height
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: filtered.map((s) {
          final flexValue = ((s['value'] ?? 0) * 100 ~/ total).clamp(1, 100);
          return Flexible(
            flex: flexValue,
            child: Container(
              decoration: BoxDecoration(
                color: s['color'],
                borderRadius: BorderRadius.horizontal(
                  left: s == filtered.first ? const Radius.circular(10) : Radius.zero,
                  right: s == filtered.last ? const Radius.circular(10) : Radius.zero,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                "${s['label']} ${s['value']}%",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.blue.shade600,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(text: "All Jobs"),
                Tab(text: "Recommended"),
                Tab(text: "Added Jobs"),
              ],
            ),
          ),
          if (_tabController.index != 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search by Company",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      searchCompany = value;
                      _filterJobs();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search by Job Role",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      searchRole = value;
                      _filterJobs();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedJobs.isEmpty
                    ? const Center(
                        child: Text(
                          "No job posts available.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          itemCount: displayedJobs.length,
                          itemBuilder: (context, index) {
                            final job = displayedJobs[index];
                            final id = job['_id']?.toString() ?? 'idx_$index';
                            entryExpandedMap.putIfAbsent(id, () => false);

                            return _buildJobCard(
                              Map<String, dynamic>.from(job),
                              isAddedTab: _tabController.index == 2,
                              index: index,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
