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

/// --- Design Constants ---
const kPrimaryColor = Color(0xFF3B82F6);
const kAppBarColor = Color.fromARGB(255, 25, 118, 210);
const kBackgroundColor = Color.fromARGB(255, 252, 252, 253);
const kCardElevation = 4.0;

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

  final Map<String, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      final storedId = await auth.getUserId();
      if (!mounted) return;

      if (storedId == null) {
        Navigator.pushReplacementNamed(context, '/signin');
        return;
      }

      userId = storedId;

      final provider =
          Provider.of<StudentOnboardingProvider>(context, listen: false);
      await provider.fetchProfile(userId!);

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error initializing user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load profile")),
        );
      }
    }
  }

  void _logout() async {
    try {
      await auth.logout();
      Provider.of<StudentOnboardingProvider>(context, listen: false)
          .clearProfile();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      debugPrint("Logout failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logout failed")),
        );
      }
    }
  }

  /// ------------------- Section Builders -------------------
  /// ------------------- Section Builders -------------------
Widget _buildSection(String type, String label, List items) {
  return Container(
    margin: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label, // <-- Use label here for display
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
                icon: const Icon(Icons.add, color: kPrimaryColor),
              )
            ],
          ),
        ),

        // Empty state
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: const Center(
              child: Text(
                "No items added yet",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ),

        // Section Items
        ...items.asMap().entries.map((entry) {
          return CollapsibleCard(
            type: type.toLowerCase(), // backend key for logic
            data: Map<String, dynamic>.from(entry.value)
              ..putIfAbsent('userId', () => userId),
            index: entry.key,
            expandedMap: _expandedMap,
            cardColor: Colors.white,
            textColor: Colors.black87,
            iconColor: kPrimaryColor,
            deleteIconColor: Colors.red,
          );
        }),
      ],
    ),
  );
}

  Widget _buildSkillsSection(List<String> skills) {
    return SkillsSection(
      skills: skills,
      onAddSkill: _showAddSkillDialog,
      onRemoveSkill: (skill) async {
        final api = SkillsApi();
        final success = await api.removeSkill(userId!, skill);
        if (success) {
          final provider =
              Provider.of<StudentOnboardingProvider>(context, listen: false);
          provider.studentProfile['skills'] =
              await api.fetchSkills(userId!);
          if (mounted) setState(() {});
        }
      },
    );
  }

  void _showAddSkillDialog() {
    String newSkill = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Skill"),
        content: TextField(
          autofocus: true,
          onChanged: (value) => newSkill = value,
          decoration: const InputDecoration(
            hintText: "Enter skill name",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (newSkill.trim().isNotEmpty) {
                final api = SkillsApi();
                final success = await api.addSkill(userId!, newSkill.trim());
                if (success) {
                  final provider = Provider.of<StudentOnboardingProvider>(
                      context,
                      listen: false);
                  provider.studentProfile['skills'] =
                      await api.fetchSkills(userId!);
                  if (mounted) setState(() {});
                }
              }
              Navigator.pop(context);
            },
            child: const Text(
              "Add",
              style: TextStyle(color: Colors.white), // <-- set text color to white
            ),
          ),
        ],
      ),
    );
  }

  /// ------------------- Main Body -------------------
  Widget _getBody(StudentOnboardingProvider provider) {
    if (isLoading || userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = provider.studentProfile;
    final skillsList = List<String>.from(profile['skills'] ?? []);

    switch (provider.selectedPage) {
      case "rank":
        return RankScreenBody(userId: userId!);
      case "jobs":
        return JobPostsScreenBody(userId: userId!);
      case "university":
        return UniversityRankingScreenBody(userId: userId!);
      case "home":
      default:
        return GestureDetector(
  behavior: HitTestBehavior.translucent, // important to detect taps on empty space
  onTap: () {
    setState(() {
      _expandedMap.clear(); // collapse all cards
    });
  },
  child: SingleChildScrollView(
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
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 10),
        _buildSection("education", "Education", profile['education'] ?? []),
        _buildSection("licenses", "Certifications & Badges", profile['licenses'] ?? []),
        _buildSection("projects", "Projects", profile['projects'] ?? []),
        _buildSection("volunteering", "Volunteering", profile['volunteering'] ?? []),
        _buildSkillsSection(skillsList),
      ],
    ),
  ),
);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentOnboardingProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: kBackgroundColor,
        drawer: _buildDrawer(provider),
        appBar: AppBar(
          backgroundColor: kAppBarColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Student Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: _getBody(provider),
      ),
    );
  }

  Widget _buildDrawer(StudentOnboardingProvider provider) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kAppBarColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                "Student Dashboard",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
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
                    title: const Text("Logout",
                        style: TextStyle(color: Colors.red)),
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
    );
  }

  Widget _drawerItem(
      IconData icon, String title, String page, StudentOnboardingProvider provider) {
    final isSelected = provider.selectedPage == page;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? kPrimaryColor : Colors.grey[800],
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

/// ------------------- SkillsSection Widget -------------------
class SkillsSection extends StatelessWidget {
  final List<String> skills;
  final VoidCallback onAddSkill;
  final Function(String) onRemoveSkill;

  const SkillsSection({
    super.key,
    required this.skills,
    required this.onAddSkill,
    required this.onRemoveSkill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Skills",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                  onPressed: onAddSkill,
                  icon: const Icon(Icons.add, color: kPrimaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          // Empty state
          if (skills.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "No skills added yet",
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((skill) => Chip(
                        label: Text(skill,
                            style: const TextStyle(color: Colors.black87)),
                        backgroundColor: Colors.white,
                        shadowColor: Colors.black12,
                        elevation: 2,
                        deleteIcon: const Icon(Icons.remove_circle,
                            size: 18, color: Color.fromARGB(255, 18, 114, 166)),
                        onDeleted: () => onRemoveSkill(skill),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
