import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/user_profile_service.dart';

/* ---------------------------- ExpandableTile (Animated) ---------------------------- */
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
              color: Colors.grey.withOpacity(0.2),
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

/* ---------------------------- ProfileHeader ---------------------------- */
class ProfileHeader extends StatefulWidget {
  final String userId;
  final String? imageUrl;
  final String? name;
  final String? bio;
  final String? location;

  const ProfileHeader({
    super.key,
    required this.userId,
    this.imageUrl,
    this.name,
    this.bio,
    this.location,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl ?? "";

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
                      widget.name ?? "No Name",
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
                        widget.bio ?? "No Bio",
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
                            widget.location ?? "Unknown",
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

/* ---------------------------- Main UserProfileScreen ---------------------------- */
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String jobPostId;
  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.jobPostId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserProfileService().fetchUserProfile(widget.userId);
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
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _urlButton(BuildContext context, String label, String url) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: ElevatedButton.icon(
      icon: const Icon(Icons.open_in_new, size: 14, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
      onPressed: () => _launchUrl(context, url),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(width: 0.5, color: Colors.black),
        ),
        elevation: 0, // removes shadow
      ),
    ),
  );
}


  void _launchUrl(BuildContext context, String url) async {
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
          ]),
      child: Text(text,
          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14)),
    );
  }

  String _truncateText(String? text, {int length = 60}) {
    if (text == null || text.isEmpty) return '';
    return text.length > length ? "${text.substring(0, length)}..." : text;
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
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final edu = data["education"] as List? ?? [];
          final licenses = data["licenses"] as List? ?? [];
          final projects = data["projects"] as List? ?? [];
          final volunteering = data["volunteering"] as List? ?? [];
          final skills = data["skills"] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ProfileHeader(
                userId: widget.userId,
                imageUrl: data['imageUrl'],
                name: data['name'],
                bio: data['bio'],
                location: data['location'],
              ),
              const SizedBox(height: 10),

              /* ------------------- Education ------------------- */
              _sectionHeader("Education"),
              if (edu.isEmpty) _emptyState("No Education Added Yet"),
              ...edu.map((e) => ExpandableTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e["school"] ?? '',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e["degree"] ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ],
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${e["field"] ?? ''}"),
                        Text("CGPA - ${e["gpa"] ?? ''}"),
                        Text("${e["description"] ?? ''}"),
                        Text("${e["startMonth"] ?? ''} ${e["startYear"] ?? ''} - ${e["endMonth"] ?? ''} ${e["endYear"] ?? ''}"),
                      ],
                    ),
                  )),

              /* ------------------- Licenses ------------------- */
              _sectionHeader("Licenses & Certifications"),
              if (licenses.isEmpty) _emptyState("No Licenses Added Yet"),
              ...licenses.map((l) {
                final List marks = l["marks"] ?? [];
                final matchedMark = marks.firstWhere(
                  (m) => m["jobPostId"]?.toString() == widget.jobPostId,
                  orElse: () => null,
                );
                return ExpandableTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l["name"] ?? "Unnamed License",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l["organization"] ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${l["issueDate"] ?? ''} - ${l["expirationDate"] ?? ''}"),
                      Text("Credential ID: ${l["credentialId"] ?? ''}"),
                      if ((l["credentialUrl"] ?? '').isNotEmpty)
                        _urlButton(context, "Show Credential", l["credentialUrl"]),
                      if (matchedMark != null)
                        Text("Mark for this Job Post: ${matchedMark["value"]}"),
                    ],
                  ),
                );
              }),

              /* ------------------- Projects ------------------- */
              _sectionHeader("Projects"),
              if (projects.isEmpty) _emptyState("No Projects Added Yet"),
              ...projects.map((p) {
                final List marks = p["marks"] ?? [];
                final matchedMark = marks.firstWhere(
                  (m) => m["jobPostId"]?.toString() == widget.jobPostId,
                  orElse: () => null,
                );

                return ExpandableTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p["name"] ?? "Untitled Project",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text("${p["description"] ?? ''}", style: const TextStyle(fontSize: 13, color: Colors.black)),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${p["startDate"] ?? ''} - ${p["endDate"] ?? ''}"),
                      if ((p["projectUrl"] ?? '').isNotEmpty)
                        _urlButton(context, "Show Project", p["projectUrl"]),
                      if (matchedMark != null)
                        Text("Mark for this Job Post: ${matchedMark["value"]}"),
                    ],
                  ),
                );
              }),

              /* ------------------- Volunteering ------------------- */
              _sectionHeader("Volunteering"),
              if (volunteering.isEmpty) _emptyState("No Volunteering Added Yet"),
              ...volunteering.map((v) => ExpandableTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v["role"] ?? '',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v["organization"] ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ],
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${v["startDate"] ?? ''} - ${v["endDate"] ?? ''}"),
                        Text("${v["cause"] ?? ''}"),
                        Text("${v["description"] ?? ''}"),
                        if ((v["url"] ?? '').isNotEmpty)
                          _urlButton(context, "Show Website", v["url"]),
                      ],
                    ),
                  )),

              /* ------------------- Skills ------------------- */
              _sectionHeader("Skills"),
              const SizedBox(height: 6),
              if (skills.isEmpty) _emptyState("No Skills Added Yet"),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map<Widget>((s) {
                  return Chip(
                    label: Text(s ?? '', style: const TextStyle(color: Colors.black87)),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ]),
          );
        },
      ),
    );
  }
}
