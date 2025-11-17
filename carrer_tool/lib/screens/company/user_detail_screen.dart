// lib/screens/user_detail_screen.dart
import 'package:carrer_tool/screens/company/services/user_marks_service.dart';
import 'package:flutter/material.dart';
import '../company/services/user_profile_service.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String jobPostId;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.jobPostId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserProfileService profileService = UserProfileService();
  final UserMarksService marksService = UserMarksService();

  late Future<Map<String, dynamic>> profileFuture;

  @override
  void initState() {
    super.initState();
    profileFuture = profileService.fetchUserProfile(widget.userId);
  }

  Future<void> submitMarks({
    required String section,
    required String itemId,
    required double value,
  }) async {
    try {
      await marksService.updateMarks(
        userId: widget.userId,
        jobPostId: widget.jobPostId,
        section: section,
        itemId: itemId,
        value: value,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marks updated successfully")),
      );
      setState(() {
        profileFuture = profileService.fetchUserProfile(widget.userId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating marks: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final profile = snapshot.data!;
          final education = profile["education"] ?? [];
          final skills = List<String>.from(profile["skills"] ?? []);
          final volunteering = profile["volunteering"] ?? [];
          final licenses = profile["licenses"] ?? [];
          final projects = profile["projects"] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profile["imageUrl"] != ""
                              ? NetworkImage(profile["imageUrl"])
                              : null,
                          child: profile["imageUrl"] == ""
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile["name"] ?? "No Name",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(profile["bio"] ?? ""),
                              const SizedBox(height: 4),
                              Text("📍 ${profile["location"] ?? ""}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Education Section
                _buildExpansionSection(
                  title: "Education",
                  icon: Icons.school,
                  children: education.map<Widget>((edu) {
                    return _buildCard(
                      title: "${edu["degree"]} in ${edu["field"]}",
                      subtitle:
                          "${edu["school"]} • ${edu["degree"]} in ${edu["field"]}\n"
                          "Period: ${edu["startMonth"]} ${edu["startYear"]} - ${edu["endMonth"]} ${edu["endYear"]}\n"
                          "GPA: ${edu["gpa"]}\n"
                          "Activities: ${edu["activities"]}\n"
                          "Description: ${edu["description"]}",
                    );
                  }).toList(),
                ),

                // Skills Section
                _buildExpansionSection(
                  title: "Skills",
                  icon: Icons.code,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: skills
                          .map((s) => Chip(label: Text(s)))
                          .toList(),
                    ),
                  ],
                ),

                // Licenses Section
                _buildExpansionSection(
                  
                  title:
                    "Certifications (${licenses.length}) | Marked: ${licenses.where((l) {
                  final marks = (l["marks"] ?? []) as List;
                  
                  // Only consider marks for the current jobPostId
                  final jobPostMarks = marks
                      .whereType<Map<String, dynamic>>()
                      .where((m) =>
                          m["jobPostId"] == widget.jobPostId && (m["value"] ?? 0) > 0)
                      .toList();

                  return jobPostMarks.isNotEmpty;
                }).length}",
                  icon: Icons.workspace_premium,


                  children: licenses.map<Widget>((license) {
                    final marksList = ((license["marks"] ?? []) as List)
                        .whereType<Map<String, dynamic>>()
                        .toList();

                    final matchingMark = marksList.isNotEmpty
                        ? marksList.firstWhere(
                            (m) => m["jobPostId"] == widget.jobPostId,
                            orElse: () => <String, dynamic>{},
                          )
                        : null;

                    final double? givenMark = (matchingMark != null &&
                            matchingMark.containsKey("value"))
                        ? (matchingMark["value"] as num).toDouble()
                        : null;

                    final controller =
                        TextEditingController(text: givenMark?.toString() ?? "");

                    return _buildCard(
                      title: license["name"],
                      subtitle:
                          "Organization: ${license["organization"]}\n"
                          "Issued: ${license["issueDate"] ?? ''}\n"
                          "Expires: ${license["expirationDate"] ?? ''}\n"
                          "Credential ID: ${license["credentialId"] ?? ''}\n"
                          "Credential URL: ${license["credentialUrl"] ?? ''}",

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Assign Marks (0-100)",
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              final value =
                                  double.tryParse(controller.text) ?? 0;
                              if (value < 0 || value > 100) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Marks should be between 0 and 100"),
                                  ),
                                );
                                return;
                              }
                              submitMarks(
                                section: "license",
                                itemId: license["_id"],
                                value: value,
                              );
                            },
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Projects Section
                _buildExpansionSection(

                  title:
                    "Projects (${projects.length}) | Marked: ${projects.where((p) {
                  final marks = (p["marks"] ?? []) as List;

                  final jobPostMarks = marks
                      .whereType<Map<String, dynamic>>()
                      .where((m) =>
                          m["jobPostId"] == widget.jobPostId && (m["value"] ?? 0) > 0)
                      .toList();

                  return jobPostMarks.isNotEmpty;
                }).length}",
                    icon: Icons.build,

                  children: projects.map<Widget>((project) {
                    final marksList = ((project["marks"] ?? []) as List)
                        .whereType<Map<String, dynamic>>()
                        .toList();

                    final matchingMark = marksList.isNotEmpty
                        ? marksList.firstWhere(
                            (m) => m["jobPostId"] == widget.jobPostId,
                            orElse: () => <String, dynamic>{},
                          )
                        : null;

                    final double? givenMark = (matchingMark != null &&
                            matchingMark.containsKey("value"))
                        ? (matchingMark["value"] as num).toDouble()
                        : null;

                    final controller =
                        TextEditingController(text: givenMark?.toString() ?? "");

                    return _buildCard(
                      title: project["name"],
                      subtitle:  
                        "Description: ${project["description"]}\n"
                        "Issued: ${project["projectUrl"] ?? ''}\n",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Assign Marks (0-100)",
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              final value =
                                  double.tryParse(controller.text) ?? 0;
                              if (value < 0 || value > 100) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Marks should be between 0 and 100"),
                                  ),
                                );
                                return;
                              }
                              submitMarks(
                                section: "project",
                                itemId: project["_id"],
                                value: value,
                              );
                            },
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Volunteering Section
                _buildExpansionSection(
                  title: "Volunteering",
                  icon: Icons.volunteer_activism,
                  children: volunteering.map<Widget>((v) {
                    return _buildCard(
                      title: "${v["organization"]} - ${v["role"]}",
                      subtitle:
                      "Cause: ${v["cause"] ?? "N/A"}\n"
                      "Duration: ${v["startDate"] ?? "N/A"} - ${v["endDate"] ?? "N/A"}\n"
                      "Link: ${v["url"] ?? "N/A"}\n"
                      "Description: ${v["description"] ?? "N/A"}",
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.all(8),
        children: children.isEmpty
            ? [const Text("No data available")]
            : children,
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    Widget? child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle),
            if (child != null) ...[
              const SizedBox(height: 8),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
