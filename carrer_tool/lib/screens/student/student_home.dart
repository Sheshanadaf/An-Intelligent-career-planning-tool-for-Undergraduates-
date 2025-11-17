import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../providers/student_onboarding_provider.dart';
import '../../services/skills_api.dart';
import 'widgets/profile_header.dart';
import 'widgets/collapsible_card.dart';
import 'widgets/add_edit_bottom_sheet.dart';
import 'rank_screen_body.dart';
import 'job_posts_screen_body.dart';
import 'university_ranking_screen_body.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key, required this.userId});
  final String userId;

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final AuthService auth = AuthService();
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final storedId = await auth.getUserId();
    if (storedId == null) {
      Navigator.pushReplacementNamed(context, '/signin');
      return;
    }
    userId = storedId;

    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
    await provider.fetchProfile(userId!);

    setState(() => isLoading = false);
  }

  void _logout() async {
    await auth.logout();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  List<Widget> _buildSection(String type, List items, Map<String, bool> expandedMap) {
    return [
      Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => showAddEditBottomSheet(context, type.toLowerCase()),
                    icon: Icon(Icons.add, color: Colors.blue.shade400),
                  )
                ],
              ),
            ),

            // Empty state
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "No items added yet",
                  style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                ),
              ),

            // Section Items
            ...items.asMap().entries.map((entry) {
              return CollapsibleCard(
                type: type.toLowerCase(),
                data: Map<String, dynamic>.from(entry.value)..putIfAbsent('userId', () => userId),
                index: entry.key,
                expandedMap: expandedMap,
                cardColor:Color.fromARGB(255, 255, 255, 255),
                textColor: const Color.fromARGB(255, 0, 0, 0),
                iconColor: const Color.fromARGB(255, 0, 119, 255),
                deleteIconColor: Colors.red,
              );
            }),
          ],
        ),
      ),
    ];
  }

  Widget _buildSkillsSection(List skillsList) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Skills",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _showAddSkillDialog,
                  icon: Icon(Icons.add, color: Colors.blue.shade400),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                )
              ],
            ),
          ),

          // Empty state
          if (skillsList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "No skills added yet",
                style: TextStyle(color: Colors.white70),
              ),
            ),

          // Skills chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skillsList.map((skill) {
              return Chip(
                label: Text(
                  skill,
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                deleteIcon: const Icon(Icons.remove_circle, size: 18, color: Color.fromARGB(255, 76, 70, 70)),
                onDeleted: () async {
                  final api = SkillsApi();
                  final success = await api.removeSkill(userId!, skill);
                  if (success) {
                    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
                    provider.studentProfile['skills'] = await api.fetchSkills(userId!);
                    setState(() {});
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog() {
    String newSkill = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Skill"),
        content: TextField(
          autofocus: true,
          onChanged: (value) => newSkill = value,
          decoration: const InputDecoration(hintText: "Enter skill name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newSkill.trim().isNotEmpty) {
                final api = SkillsApi();
                final success = await api.addSkill(userId!, newSkill.trim());
                if (success) {
                  final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
                  provider.studentProfile['skills'] = await api.fetchSkills(userId!);
                  setState(() {});
                }
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _getBody(StudentOnboardingProvider provider) {
    if (isLoading || userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = provider.studentProfile;
    final skillsList = (profile['skills'] as List?) ?? [];
    final Map<String, bool> expandedMap = {};

    switch (provider.selectedPage) {
      case "rank":
        return RankScreenBody(userId: userId!);
      case "jobs":
        return JobPostsScreenBody(userId: userId!);
      case "university":
        return UniversityRankingScreenBody(userId: userId!);
      case "home":
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(
                userId: userId!,
                imageUrl: profile['imageUrl'],
                name: profile['name'],
                bio: profile['bio'],
                location: profile['location'],
                onUpdated: (newProfile) async {
                  await provider.fetchProfile(userId!);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              ..._buildSection("Education", profile['education'] ?? [], expandedMap),
              ..._buildSection("Licenses", profile['licenses'] ?? [], expandedMap),
              ..._buildSection("Projects", profile['projects'] ?? [], expandedMap),
              ..._buildSection("Volunteering", profile['volunteering'] ?? [], expandedMap),
              _buildSkillsSection(skillsList),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentOnboardingProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: const Color.fromARGB(255,252, 252, 253),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: Colors.blue.shade400,
                  child: const Text(
                    "Student Dashboard",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _drawerItem(Icons.person, "Profile", "home", provider),
                      _drawerItem(Icons.school, "Rank", "rank", provider),
                      _drawerItem(Icons.info, "Info", "university", provider),
                      _drawerItem(Icons.work, "Jobs", "jobs", provider),
                      _drawerItem(Icons.settings, "Settings", "settings", provider),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text("Logout", style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _logout();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.blue.shade400,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Student Dashboard", style: TextStyle(color: Colors.white)),
        ),
        body: _getBody(provider),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String page, StudentOnboardingProvider provider) {
    final isSelected = provider.selectedPage == page;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue.shade400 : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade400 : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        provider.setSelectedPage(page);
        Navigator.pop(context);
      },
    );
  }
}
