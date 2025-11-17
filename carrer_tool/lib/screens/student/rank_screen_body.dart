import 'package:flutter/material.dart';
import '../../services/rank_api.dart';
import '../student/rank_result_screen.dart';

class RankScreenBody extends StatefulWidget {
  final String userId;

  const RankScreenBody({super.key, required this.userId});

  @override
  State<RankScreenBody> createState() => _RankScreenBodyState();
}

class _RankScreenBodyState extends State<RankScreenBody> {
  String? selectedCompany;
  String? selectedJobRole;

  List<String> companies = [];
  List<String> jobRoles = [];
  bool isLoadingCompanies = true;
  bool isLoadingJobRoles = false;
  bool isJobDetailsExpanded = false; // <-- add this state variable
  Map<String, bool> entryExpandedMap = {}; 

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
          weights.updateAll((key, value) =>
              apiWeights.containsKey(key) ? (apiWeights[key] as int) : 0);
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching job details: $e");
    }
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
    int nearest = stepOptions.reduce((a, b) =>
        (value - a).abs() < (value - b).abs() ? a : b);

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
        const SnackBar(content: Text("Total weight must be 100% to proceed")),
      );
      return;
    }

    bool success = await RankApi.submitRank(
      company: selectedCompany!,
      jobRole: selectedJobRole!,
      weights: weights,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Rank submitted!" : "Submit failed. Try again."),
      ),
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

  @override
  Widget build(BuildContext context) {
    int total = weights.values.reduce((a, b) => a + b);

    Color primaryBlue = Colors.blue.shade600;
    Color grayBorder = Colors.grey.shade300;
    Color textPrimary = Colors.black87;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 253),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rank Preferences",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold, color: primaryBlue)),
            const SizedBox(height: 20),

            // Company Dropdown
            isLoadingCompanies
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: grayBorder)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Company",
                          border: InputBorder.none,
                        ),
                        value: selectedCompany,
                        dropdownColor: const Color.fromARGB(255, 255, 255, 255), 
                        items: companies
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          setState(() => selectedCompany = val);
                          fetchJobRoles(val!);
                        },
                      ),
                    ),
                  ),

            const SizedBox(height: 16),

            // Job Role Dropdown
            isLoadingJobRoles
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: grayBorder)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Job Role",
                          border: InputBorder.none,
                        ),
                        value: selectedJobRole,
                        dropdownColor: const Color.fromARGB(255, 255, 255, 255), 
                        items: jobRoles
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          setState(() => selectedJobRole = val);
                          loadJobDetails();
                        },
                      ),
                    ),
                  ),

            const SizedBox(height: 24),
            
            // Job Details card
            if (selectedCompany != null && selectedJobRole != null) ...[
              const SizedBox(height: 12),
              if (isLoadingJobDetails)
                const Center(child: CircularProgressIndicator())
              else if (jobDetails != null)
                SizedBox(
                  width: double.infinity, // Full width
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: grayBorder, width: 1.5),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          isJobDetailsExpanded = !isJobDetailsExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Expand Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Job Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: isJobDetailsExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Collapsed Preview
                            if (!isJobDetailsExpanded)
                              Text(
                                jobDetails!["description"] ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                              ),

                            // Expanded Details
                            if (isJobDetailsExpanded)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 300, // scrollable area height
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      for (var entry in [
                                        ["Job Description", jobDetails!["description"]],
                                        [
                                          "Required Skills",
                                          (jobDetails!["skills"] as List?)?.join(", ") ??
                                              "No skills listed"
                                        ],
                                        [
                                          "Certifications",
                                          jobDetails!["certifications"] ?? "No info"
                                        ],
                                        [
                                          "Additional Details",
                                          jobDetails!["details"] ?? "Not specified"
                                        ],
                                        [
                                          "Weight Distribution",
                                          (jobDetails!["weights"] as Map?)?.entries
                                                  .map((e) =>
                                                      "${displayNames[e.key] ?? e.key}: ${e.value}%")
                                                  .join(", ") ??
                                              "No weights data"
                                        ],
                                      ])
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry[0],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                entry[1] ?? "",
                                                style: TextStyle(
                                                    fontSize: 14, color: Colors.grey[800]),
                                              ),
                                              const Divider(height: 16, thickness: 1),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),

            Text("Adjust Weightage",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: grayBorder)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Allocated: $total%",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text("Remaining: ${100 - total}%"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...weights.keys.map((key) {
                      String displayName = displayNames[key] ?? key;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$displayName (${weights[key]}%)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: primaryBlue,
                              inactiveTrackColor: grayBorder,
                              thumbColor: primaryBlue,
                              overlayColor: primaryBlue.withAlpha(32),
                              trackHeight: 6,
                            ),
                            child: Slider(
                              value: weights[key]!.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 5,
                              label: "$displayName ${weights[key]}%",
                              onChanged: isSliderDisabled(key)
                                  ? null
                                  : (val) => updateWeight(key, val),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            Center(
              child: ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("View Rank",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
