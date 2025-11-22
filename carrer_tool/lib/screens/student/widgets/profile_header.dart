import 'package:flutter/material.dart';
import '../../../screens/student/widgets/edit_profile_sheet.dart';
import '../helpers/utils.dart';

class ProfileHeader extends StatefulWidget {
  final String userId;
  final String? imageUrl;
  final String? name;
  final String? bio;
  final String? location;
  final Function(Map<String, dynamic>)? onUpdated;

  const ProfileHeader({
    super.key,
    required this.userId,
    this.imageUrl,
    this.name,
    this.bio,
    this.location,
    this.onUpdated,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = getFullImageUrl(widget.imageUrl);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0), // slower animation
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildCollapsed(fullImageUrl),
          secondChild: _buildExpanded(fullImageUrl),
        ),
      ),
    );
  }

  // ---------------- COLLAPSED STATE ----------------
  Widget _buildCollapsed(String fullImageUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white,
          backgroundImage: fullImageUrl.isNotEmpty
              ? NetworkImage(fullImageUrl)
              : const AssetImage("assets/asd.jpg") as ImageProvider,
        ),
        const SizedBox(width: 16),
        // Name, Location, Bio (one line)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name ?? "No name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.location ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.bio ?? "No bio",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white, size: 16),
          onPressed: _openEditSheet,
        ),
      ],
    );
  }

  // ---------------- EXPANDED STATE ----------------
  Widget _buildExpanded(String fullImageUrl) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16), // add some top padding
              AnimatedAlign(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  backgroundImage: fullImageUrl.isNotEmpty
                      ? NetworkImage(fullImageUrl)
                      : const AssetImage("assets/asd.jpg") as ImageProvider,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.name ?? "No name",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    widget.location ?? "Unknown",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),

          // Positioned edit button at top-right
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _openEditSheet,
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),
      AnimatedSize(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              widget.bio ?? "No bio",
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => EditProfileSheet(
        userId: widget.userId,
        name: widget.name,
        bio: widget.bio,
        location: widget.location,
        imageUrl: widget.imageUrl,
        onProfileUpdated: (updatedData) {
          widget.onUpdated?.call(updatedData);
        },
      ),
    );
  }
}
