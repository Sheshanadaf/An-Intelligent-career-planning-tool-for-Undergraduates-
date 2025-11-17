import 'package:flutter/material.dart';
import '../company/services/company_api.dart';
import 'view_rank_screen.dart';

class CompanyHomeBody extends StatefulWidget {
  final String companyName;
  final String companyReg;
  final String companyLogo;

  const CompanyHomeBody({
    super.key,
    required this.companyName,
    required this.companyReg,
    required this.companyLogo,
  });

  @override
  State<CompanyHomeBody> createState() => _CompanyHomeBodyState();
}

class _CompanyHomeBodyState extends State<CompanyHomeBody> {
  List<dynamic> jobPosts = [];
  bool isLoading = true;
  final companyApi = CompanyApi();
  final Set<String> expandedJobs = {}; // track which cards are expanded

  @override
  void initState() {
    super.initState();
    loadJobPosts();
  }

  Future<void> loadJobPosts() async {
    final posts = await companyApi.fetchCompanyPosts();
    setState(() {
      jobPosts = posts;
      isLoading = false;
    });
  }

  void toggleExpanded(String jobId) {
    setState(() {
      if (expandedJobs.contains(jobId)) {
        expandedJobs.remove(jobId);
      } else {
        expandedJobs.add(jobId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ======================
          // 🔹 Company Header Section
          // ======================
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: widget.companyLogo.isNotEmpty
                    ? NetworkImage(widget.companyLogo)
                    : null,
                child: widget.companyLogo.isEmpty
                    ? const Icon(Icons.business, size: 35)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.companyName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Reg No: ${widget.companyReg}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ======================
          // 🔹 Job Posts Section
          // ======================
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Your Job Posts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (jobPosts.isEmpty)
            const Center(
              child: Text(
                "No job posts available.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: jobPosts.map((post) {
                final jobRole = post['jobRole'] ?? 'Unknown Role';
                final jobDescription = post['description'] ?? 'No description';
                final skills = post['skills'] ?? 'No skills listed';
                final certificates = post['certifications'] ?? 'No certificates';
                final details = post['details'] ?? 'No extra details';
                final weights = post['weights'] != null ? Map<String, dynamic>.from(post['weights']) : {"university": 0,"gpa": 0,"certifications": 0,"projects": 0,};// convert to Map
    

                final companyId = post['companyId'] ?? '';
                final jobPostId = post['_id'] ?? '';

                final isExpanded = expandedJobs.contains(jobPostId);

                return GestureDetector(
                  onTap: () => toggleExpanded(jobPostId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                jobRole,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Expanded details
                        if (isExpanded) ...[
                          Text(
                            "Description: $jobDescription",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Skills: $skills",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Certificates: $certificates",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Details: $details",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Weights: $weights",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // View Rank button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewRankScreen(
                                    jobRole: jobRole,
                                    companyId: companyId,
                                    jobPostId: jobPostId,
                                    weights:weights,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bar_chart),
                            label: const Text("View Rank"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
