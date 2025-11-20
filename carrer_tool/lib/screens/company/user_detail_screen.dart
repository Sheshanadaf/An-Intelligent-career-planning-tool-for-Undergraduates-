import 'package:flutter/material.dart';
import 'package:carrer_tool/screens/company/services/user_marks_service.dart';
import '../company/services/user_profile_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// ---------------------------- ExpandableTile (Animated) ----------------------------
class ExpandableTile extends StatefulWidget {
  final Widget title;
  final Widget content;

  const ExpandableTile({super.key, required this.title, required this.content});

  @override
  State<ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.title,
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: widget.content,
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------- Profile Header ----------------------------
class ProfileHeader extends StatefulWidget {
  final Map<String, dynamic> profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final imageUrl = profile["imageUrl"] ?? "";

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2563EB),
                Color(0xFF3B82F6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage("assets/asd.jpg") as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile["name"] ?? "No Name",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Text(
                        profile["bio"] ?? "No Bio",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile["location"] ?? "Unknown",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------- UserDetailScreen ----------------------------
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

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot open this URL.")),
        );
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open URL.")),
      );
    }
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// ---------------------------- URL Button ----------------------------
  Widget _urlButton(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton.icon(
        onPressed: () => _launchUrl(url),
        icon: const Icon(Icons.link, size: 16, color: Colors.black87),
        label: Text(label,
            style: const TextStyle(color: Colors.black87, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  /// ---------------------------- Build Mark Section ----------------------------
  Widget _buildMarksSection({
    required Map<String, dynamic> item,
    required String sectionName,
  }) {
    final marksList = ((item["marks"] ?? []) as List)
        .whereType<Map<String, dynamic>>()
        .toList();

    final matchingMark = marksList.isNotEmpty
        ? marksList.firstWhere(
            (m) => m["jobPostId"] == widget.jobPostId,
            orElse: () => <String, dynamic>{},
          )
        : null;

    final double? givenMark =
        (matchingMark != null && matchingMark.containsKey("value") && (matchingMark["value"] as num) > 0)
            ? (matchingMark["value"] as num).toDouble()
            : null;

    final controller = TextEditingController(text: givenMark?.toString() ?? "");

    // Determine title text for volunteering
    Widget titleWidget;
    if (sectionName == "volunteering") {
      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item["role"] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(item["organization"] ?? ''),
        ],
      );
    } else {
      titleWidget = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["name"] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (sectionName == "project")
                  Text(item["description"] ?? '')
                else if (sectionName == "license")
                  Text(item["organization"] ?? ''),
              ],
            ),
          ),
          if (givenMark != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("Marked", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      );
    }

    return ExpandableTile(
      title: titleWidget,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionName == "license")
            Text("Issue: ${item["issueDate"] ?? ''} - Expiry: ${item["expirationDate"] ?? ''}"),
          if (sectionName == "license" && (item["credentialId"] ?? '').isNotEmpty)
            Text("Credential ID: ${item["credentialId"] ?? ''}"),
          if (sectionName == "project" || sectionName == "volunteering")
            Text(
              "Duration: ${item["startDate"] ?? ''} - ${item["endDate"] ?? ''}",
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          if (sectionName == "volunteering" && (item["cause"] ?? '').isNotEmpty)
            Text("Cause: ${item["cause"] ?? ''}"),
          if (sectionName == "volunteering" && (item["description"] ?? '').isNotEmpty)
            Text("Description: ${item["description"] ?? ''}"),
          const SizedBox(height: 6),
          // ------------------- Marks input + Submit button -------------------
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 36,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: "0-100",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 6),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {
                    final value = double.tryParse(controller.text);
                    if (value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid number")),
                      );
                      return;
                    }
                    if (value < 0 || value > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Marks should be between 0 and 100")),
                      );
                      return;
                    }
                    submitMarks(section: sectionName, itemId: item["_id"], value: value);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.blue.shade600),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.blue.shade600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          // ------------------- URL Buttons -------------------
          if (sectionName == "license" && (item["credentialUrl"] ?? '').isNotEmpty)
            _urlButton("Show Credential", item["credentialUrl"]),
          if (sectionName == "project" && (item["projectUrl"] ?? '').isNotEmpty)
            _urlButton("Show Project", item["projectUrl"]),
          if (sectionName == "volunteering" && (item["url"] ?? '').isNotEmpty)
            _urlButton("Show Website", item["url"]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 118, 210),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("User Profile", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final profile = snapshot.data!;
          final education = profile["education"] ?? [];
          final skills = List<String>.from(profile["skills"] ?? []);
          final volunteering = profile["volunteering"] ?? [];
          final licenses = profile["licenses"] ?? [];
          final projects = profile["projects"] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------- Profile Header -------------------
                ProfileHeader(profile: profile),

                // ------------------- Education -------------------
                _sectionHeader("Education"),
                if (education.isEmpty) _emptyState("No Education Added Yet"),
                ...education.map((edu) => ExpandableTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(edu["school"] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(edu["degree"] ?? '', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Field: ${edu["field"] ?? ''}"),
                          Text("CGPA: ${edu["gpa"] ?? ''}"),
                          Text("${edu["startMonth"] ?? ''} ${edu["startYear"] ?? ''} - ${edu["endMonth"] ?? ''} ${edu["endYear"] ?? ''}"),
                          Text("${edu["description"] ?? ''}"),
                        ],
                      ),
                    )),

                // ------------------- Licenses & Certifications -------------------
                _sectionHeader("Licenses & Certifications"),
                if (licenses.isEmpty) _emptyState("No Licenses Added Yet"),
                ...licenses.map((l) => _buildMarksSection(item: l, sectionName: "license")),

                // ------------------- Projects -------------------
                _sectionHeader("Projects"),
                if (projects.isEmpty) _emptyState("No Projects Added Yet"),
                ...projects.map((p) => _buildMarksSection(item: p, sectionName: "project")),

                // ------------------- Volunteering -------------------
                _sectionHeader("Volunteering"),
                if (volunteering.isEmpty) _emptyState("No Volunteering Added Yet"),
                ...volunteering.map((v) => _buildMarksSection(item: v, sectionName: "volunteering")),

                // ------------------- Skills -------------------
                _sectionHeader("Skills"),
                const SizedBox(height: 6),
                if (skills.isEmpty) _emptyState("No Skills Added Yet"),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: skills.map<Widget>((s) {
                    return Chip(
                      label: Text(s, style: const TextStyle(color: Colors.black87)),
                      backgroundColor: Colors.white,
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
}
