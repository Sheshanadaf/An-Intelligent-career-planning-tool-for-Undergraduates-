import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/student_onboarding_provider.dart';
import '../widgets/add_edit_bottom_sheet.dart';

class CollapsibleCard extends StatefulWidget {
  final String type;
  final Map<String, dynamic> data;
  final int index;
  final Map<String, bool> expandedMap;

  final Color? cardColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? deleteIconColor;

  const CollapsibleCard({
    super.key,
    required this.type,
    required this.data,
    required this.index,
    required this.expandedMap,
    this.cardColor,
    this.textColor,
    this.iconColor,
    this.deleteIconColor,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  bool get isExpanded => widget.expandedMap[widget.index.toString()] ?? false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);

    String getEducationDuration() {
      final startMonth = widget.data["startMonth"] ?? "";
      final startYear = widget.data["startYear"] ?? "";
      final endMonth = widget.data["endMonth"] ?? "";
      final endYear = widget.data["endYear"] ?? "";
      return "$startMonth $startYear - $endMonth $endYear";
    }

    String getLicenseDuration() {
      final issueDate = widget.data["issueDate"] ?? "";
      final expirationDate = widget.data["expirationDate"] ?? "";
      if (issueDate.isEmpty && expirationDate.isEmpty) return "";
      return "$issueDate - $expirationDate";
    }

    String getVolDuration() {
      final startDate = widget.data["startDate"] ?? "";
      final endDate = widget.data["endDate"] ?? "";
      if (startDate.isEmpty && endDate.isEmpty) return "";
      return "$startDate - $endDate";
    }

    String getProjectDuration() {
      final startDate = widget.data["startDate"] ?? "";
      final endDate = widget.data["endDate"] ?? "";
      if (startDate.isEmpty && endDate.isEmpty) return "";
      return "$startDate - $endDate";
    }

    String getTitle() {
      switch (widget.type) {
        case "education":
          return widget.data['school'] ?? "Education Item";
        case "licenses":
          return widget.data['name'] ?? "License Item";
        case "projects":
          return widget.data['name'] ?? "Project Item";
        case "volunteering":
          return widget.data['role'] ?? "Volunteering Item";
        default:
          return "Item";
      }
    }

    String? getCollapsedSummary() {
      switch (widget.type) {
        case "education":
          return widget.data['degree'] ?? '';
        case "licenses":
          return widget.data['organization'] ?? '';
        case "projects":
          return getProjectDuration();
        case "volunteering":
          return widget.data['organization'] ?? '';
        default:
          return '';
      }
    }

    // Updated _launchUrl with BuildContext
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

    Widget _buildSmallButton(
      String text,
      String url, {
      Color bgColor = const Color.fromARGB(255, 255, 255, 255),
      Color textColor = const Color.fromARGB(255, 0, 0, 0),
      double borderRadius = 6.0,
      double borderWidth = 0.5,
      Color borderColor = const Color.fromARGB(255, 0, 0, 0),
    }) {
      return ElevatedButton.icon(
        icon: Icon(Icons.open_in_new, size: 14, color: textColor),
        label: Text(
          text,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
        onPressed: () => _launchUrl(context, url),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(width: borderWidth, color: borderColor),
          ),
          elevation: 0, // removes shadow
        ),
      );
    }

    List<Widget> buildExpandedDetails() {
      List<Widget> details = [];

      switch (widget.type) {
        case "education":
          details.add(Text(
            "${widget.data['degree'] ?? ''}   |   ${widget.data['field'] ?? ''}",
            style: TextStyle(color: widget.textColor ?? Colors.black),
          ));
          details.add(Text(
            "Year: ${widget.data['year'] ?? ''}",
            style: TextStyle(color: widget.textColor ?? Colors.black),
          ));
          details.add(Text(
            "CGPA: ${widget.data['gpa'] ?? ''}",
            style: TextStyle(color: widget.textColor ?? Colors.black),
          ));
          details.add(Text(getEducationDuration(),
              style: TextStyle(color: widget.textColor ?? Colors.black54)));
          if ((widget.data['description'] ?? '').isNotEmpty) {
            details.add(
              Text(
                widget.data['description'],
                textAlign: TextAlign.justify,   // <-- Justify alignment
                style: TextStyle(
                  color: widget.textColor ?? Colors.black54,
                ),
              ),
            );
          }
          // Edit/Delete buttons for education
          details.add(Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: widget.iconColor ?? Colors.white, size: 20),
                onPressed: () {
                  showAddEditBottomSheet(
                    context,
                    widget.type,
                    existingData: widget.data,
                    index: widget.index,
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: widget.deleteIconColor ?? Colors.red, size: 20),
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Item"),
                      content: const Text("Are you sure you want to delete this item?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    provider.removeEducation(widget.index);
                    final success = await provider.updateProfile();
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to delete item. Try again.")),
                      );
                    }
                  }
                },
              ),
            ],
          ));
          break;

        case "licenses":
          details.add(Text(
              "${widget.data['organization'] ?? ''}",
              style: TextStyle(color: widget.textColor ?? Colors.black)));
          details.add(Text(getLicenseDuration(),
              style: TextStyle(color: widget.textColor ?? Colors.black54)));
          if ((widget.data['credentialId'] ?? '').isNotEmpty) {
            details.add(Text("Credential ID: ${widget.data['credentialId']}",
                style: TextStyle(color: widget.textColor ?? Colors.black54)));
          }
          if ((widget.data['credentialUrl'] ?? '').isNotEmpty) {
            details.add(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallButton("Show Credential", widget.data['credentialUrl']),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: widget.iconColor ?? Colors.white, size: 20),
                      onPressed: () {
                        showAddEditBottomSheet(
                          context,
                          widget.type,
                          existingData: widget.data,
                          index: widget.index,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: widget.deleteIconColor ?? Colors.red, size: 20),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Item"),
                            content: const Text("Are you sure you want to delete this item?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          provider.removeLicense(widget.index);
                          final success = await provider.updateProfile();
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to delete item. Try again.")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                )
              ],
            ));
          }
          break;

        case "projects":
          details.add(Text(getProjectDuration(),
              style: TextStyle(color: widget.textColor ?? Colors.black54)));
          if ((widget.data['description'] ?? '').isNotEmpty) {
            details.add(Text(widget.data['description'],
                style: TextStyle(color: widget.textColor ?? Colors.black54)));
          }
          if ((widget.data['projectUrl'] ?? '').isNotEmpty) {
            details.add(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallButton("Show Project", widget.data['projectUrl']),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: widget.iconColor ?? Colors.white, size: 20),
                      onPressed: () {
                        showAddEditBottomSheet(
                          context,
                          widget.type,
                          existingData: widget.data,
                          index: widget.index,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: widget.deleteIconColor ?? Colors.red, size: 20),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Item"),
                            content: const Text("Are you sure you want to delete this item?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          provider.removeProject(widget.index);
                          final success = await provider.updateProfile();
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to delete item. Try again.")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                )
              ],
            ));
          }
          break;

        case "volunteering":
          details.add(Text(
              "${widget.data['organization'] ?? ''}   |   ${widget.data['cause'] ?? ''} Cause",
              style: TextStyle(color: widget.textColor ?? Colors.black)));
          details.add(Text(getVolDuration(),
              style: TextStyle(color: widget.textColor ?? Colors.black54)));
          if ((widget.data['description'] ?? '').isNotEmpty) {
            details.add(Text(widget.data['description'],
                style: TextStyle(color: widget.textColor ?? Colors.black54)));
          }
          if ((widget.data['url'] ?? '').isNotEmpty) {
            details.add(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallButton("Show WebSite", widget.data['url']),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: widget.iconColor ?? Colors.white, size: 20),
                      onPressed: () {
                        showAddEditBottomSheet(
                          context,
                          widget.type,
                          existingData: widget.data,
                          index: widget.index,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: widget.deleteIconColor ?? Colors.red, size: 20),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Item"),
                            content: const Text("Are you sure you want to delete this item?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          provider.removeVolunteering(widget.index);
                          final success = await provider.updateProfile();
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to delete item. Try again.")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                )
              ],
            ));
          }
          break;
      }

      return details
          .map((e) => Padding(padding: const EdgeInsets.only(bottom: 6), child: e))
          .toList();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.expandedMap[widget.index.toString()] = !isExpanded;
        });
      },
      child: Card(
        color: widget.cardColor ?? Colors.grey.shade800,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Color.fromARGB(255, 169, 170, 164),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(getTitle(),
                  style: TextStyle(color: widget.textColor ?? Colors.white)),
              subtitle: !isExpanded
                  ? Text(getCollapsedSummary() ?? '',
                      style: TextStyle(color: widget.textColor?.withOpacity(0.8) ??
                          Colors.white70))
                  : null,
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: buildExpandedDetails(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
