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

  Widget _buildJobCard(Map<String, dynamic> job, {bool isAddedTab = false}) {
    Color primaryBlue = Colors.blue.shade600;
    Color borderGray = Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 173, 205, 250),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.blue.shade50,
          backgroundImage: job['companyLogo'] != null
              ? NetworkImage(job['companyLogo'])
              : null,
          child: job['companyLogo'] == null
              ? const Icon(Icons.business, color: Colors.blue)
              : null,
        ),
        title: Text(
          job['jobRole'] ?? "Unknown Role",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          job['companyName'] ?? "Unknown Company",
          style: const TextStyle(color: Colors.black54),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildDetailRow("Description", job['description']),
          _buildDetailRow("Skills", job['skills']),
          _buildDetailRow("Certifications", job['certifications']),
          _buildDetailRow("Details", job['details']),
          if (job['weights'] != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Weight Distribution:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("University: ${job['weights']['university']}%"),
                  Text("GPA: ${job['weights']['gpa']}%"),
                  Text("Certifications: ${job['weights']['certifications']}%"),
                  Text("Projects: ${job['weights']['projects']}%"),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                bool success;
                if (isAddedTab) {
                  success =
                      await api.removeJobFromUser(widget.userId, job['_id']);
                  if (success) {
                    setState(() {
                      addedJobs.removeWhere((j) => j['_id'] == job['_id']);
                      displayedJobs = List.from(addedJobs);
                    });
                  }
                } else {
                  success = await api.addJobToUser(widget.userId, job['_id']);
                }

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(12),
                  content: Text(success
                      ? (isAddedTab
                          ? "🗑️ Removed '${job['jobRole']}' from your jobs."
                          : "✅ Added '${job['jobRole']}' to your jobs!")
                      : "❌ Operation failed. Try again."),
                ));

                if (isAddedTab && success) {
                  await _loadJobs();
                }
              },
              icon: Icon(isAddedTab ? Icons.delete_outline : Icons.add),
              label: Text(isAddedTab ? "Remove" : "Add to My Jobs"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAddedTab ? Colors.red.shade400 : primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value.toString()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primaryBlue = Colors.blue.shade600;

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: primaryBlue,
            unselectedLabelColor: const Color.fromARGB(255, 0, 0, 0),
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: "All Jobs"),
              Tab(text: "Recommended"),
              Tab(text: "Added Jobs"),
            ],
          ),
        ),

        // 🟦 Search Fields (hidden in Recommended)
        if (_tabController.index != 1)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search by Company",
                    prefixIcon: Icon(Icons.business),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade600,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    searchCompany = value;
                    _filterJobs();  // <-- This is the missing part
                  },
                ),


                const SizedBox(height: 8),
               TextField(
                decoration: InputDecoration(
                  hintText: "Search by Job Role",
                  prefixIcon: const Icon(Icons.work_outline),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400, // 👈 border color
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400, // 👈 border color when not focused
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600, // 👈 border color when focused
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  searchRole = value;
                  _filterJobs();
                },
              )
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
                        style: TextStyle(
                            fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: ListView.builder(
                        itemCount: displayedJobs.length,
                        itemBuilder: (context, index) {
                          final job = displayedJobs[index];
                          return _buildJobCard(
                            Map<String, dynamic>.from(job),
                            isAddedTab: _tabController.index == 2,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
