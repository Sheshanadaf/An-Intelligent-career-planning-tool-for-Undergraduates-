// --- MODERN PROFESSIONAL UI REWRITE ---

import 'package:flutter/material.dart';
import '../../services/rank_api.dart';
import '../student/rank_result_screen.dart';

class RankScreenBody extends StatefulWidget {
  final String userId;

  const RankScreenBody({super.key, required this.userId});

  @override
  State<RankScreenBody> createState() => _RankScreenBodyState();
}

class _RankScreenBodyState extends State<RankScreenBody>
    with SingleTickerProviderStateMixin {
  String? selectedCompany;
  String? selectedJobRole;

  List<String> companies = [];
  List<String> jobRoles = [];
  bool isLoadingCompanies = true;
  bool isLoadingJobRoles = false;
  bool isJobDetailsExpanded = false;

  Map<String, dynamic>? jobDetails;
  bool isLoadingJobDetails = false;

  final List<int> stepOptions = [0, 20, 40, 60, 80, 100];

  Map<String, int> weights = {
    "university": 0,
    "gpa": 0,
    "certifications": 0,
    "projects": 0,
  };

  final Map<String, String> displayNames = {
    "university": "University",
    "gpa": "Current GPA",
    "certifications": "Certifications",
    "projects": "Projects",
  };

  @override
  void initState() {
    super.initState();
    RankApi.clearCache();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    setState(() => isLoadingCompanies = true);
    companies = await RankApi.fetchCompanies();
    setState(() => isLoadingCompanies = false);
  }

  Future<void> fetchJobRoles(String company) async {
    setState(() {
      isLoadingJobRoles = true;
      jobRoles = [];
      selectedJobRole = null;
    });
    jobRoles = await RankApi.fetchJobRoles(company);
    setState(() => isLoadingJobRoles = false);
  }

  Future<void> loadJobDetails() async {
    if (selectedCompany == null || selectedJobRole == null) return;
    setState(() => isLoadingJobDetails = true);

    try {
      jobDetails = await RankApi.fetchJobDetails(
        company: selectedCompany!,
        jobRole: selectedJobRole!,
      );

      if (jobDetails?["weights"] != null) {
        Map<String, dynamic> apiWeights = jobDetails!["weights"];
        setState(() {
          weights.updateAll(
            (key, value) => apiWeights.containsKey(key) ? apiWeights[key] : 0,
          );
        });
      }
    } catch (e) {}

    setState(() => isLoadingJobDetails = false);
  }

  int _sumOthers(String key) =>
      weights.entries.where((e) => e.key != key).fold(0, (sum, e) => sum + e.value);

  int remainingPercentage(String key) =>
      (100 - _sumOthers(key)).clamp(0, 100);

  bool isSliderDisabled(String key) {
    int total = weights.values.reduce((a, b) => a + b);
    if (weights[key]! > 0) return false;
    return total == 100;
  }

  void updateWeight(String key, double value) {
    int nearest = stepOptions.reduce(
        (a, b) => (value - a).abs() < (value - b).abs() ? a : b);

    int maxAllowed = remainingPercentage(key);
    if (nearest > maxAllowed) nearest = maxAllowed;

    setState(() => weights[key] = nearest);

    if (nearest == 100) {
      setState(() => weights.updateAll((k, v) => k == key ? 100 : 0));
    }
  }

  void submit() async {
    int total = weights.values.reduce((a, b) => a + b);

    if (selectedCompany == null || selectedJobRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select company and job role")),
      );
      return;
    }

    if (total < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total weight must reach 100%")),
      );
      return;
    }

    bool success = await RankApi.submitRank(
      company: selectedCompany!,
      jobRole: selectedJobRole!,
      weights: weights,
    );

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RankResultScreen(
            userId: widget.userId,
            companyName: selectedCompany!,
            jobRole: selectedJobRole!,
            jobPostId: jobDetails?["jobPostId"] ?? "",
            weights: weights,
          ),
        ),
      );
    }
  }

  // --------------------------- UI ELEMENTS -----------------------------

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = Colors.blue.shade600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),

      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, Colors.blue.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Page Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rank Preferences",
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Customize your ranking weight distribution",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------ MAIN FORM CONTAINER -------------------
                _glassCard(
                  child: Column(
                    children: [
                      // Company Dropdown
                      Theme(
                        data: Theme.of(context).copyWith(
                          dialogBackgroundColor: Colors.white,
                          canvasColor: Colors.white,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Company",
                          ),
                          value: selectedCompany,
                          items: companies
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            setState(() => selectedCompany = val);
                            fetchJobRoles(val!);
                          },
                        ),
                      ),
                      // Job Role Dropdown
                      Theme(
                        data: Theme.of(context).copyWith(
                          dialogBackgroundColor: Colors.white,
                          canvasColor: Colors.white,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Job Role",
                          ),
                          value: selectedJobRole,
                          items: jobRoles
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (val) {
                            setState(() => selectedJobRole = val);
                            loadJobDetails();
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Job Details
                      if (selectedCompany != null &&
                          selectedJobRole != null)
                        _buildJobDetailsCard(),

                      const SizedBox(height: 20),

                      // Weight Adjustment Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Weight Distribution",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      ...weights.keys.map((key) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${displayNames[key]} (${weights[key]}%)",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),

                              Slider(
                                value: weights[key]!.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 5,
                                activeColor: primaryBlue,
                                onChanged: isSliderDisabled(key)
                                    ? null
                                    : (val) => updateWeight(key, val),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 42, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "View Rank",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------------------

  Widget _buildJobDetailsCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => isJobDetailsExpanded = !isJobDetailsExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Job Details",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                AnimatedRotation(
                  turns: isJobDetailsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down),
                )
              ],
            ),
          ),

          if (!isJobDetailsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                jobDetails?["description"] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),

          if (isJobDetailsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailItem("Job Description",
                      jobDetails?["description"] ?? ""),
                  _detailItem("Required Skills",
                      (jobDetails?["skills"] as List?)?.join(", ") ?? "-"),
                  _detailItem(
                      "Certifications", jobDetails?["certifications"] ?? "-"),
                  _detailItem("Additional Details",
                      jobDetails?["details"] ?? "-"),

                  // Add the weight bar here
                  if (jobDetails?["weights"] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      "Weight Distribution",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    _buildWeightBar(jobDetails!["weights"]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // --------------------------- WEIGHT BAR METHOD ------------------------
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
      height: 20,
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
}
