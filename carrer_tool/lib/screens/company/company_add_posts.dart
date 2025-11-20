import 'dart:ui';
import 'package:flutter/material.dart';
import 'services/company_api.dart';

class CompanyAddPosts extends StatefulWidget {
  final String companyName;
  final String companyReg;
  final String companyDis;
  final String? companyLogo;

  const CompanyAddPosts({
    super.key,
    required this.companyName,
    required this.companyReg,
    required this.companyDis,
    this.companyLogo, required companyId,
  });

  @override
  State<CompanyAddPosts> createState() => _CompanyAddPostsState();
}

class _CompanyAddPostsState extends State<CompanyAddPosts>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _roleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _skillsCtl = TextEditingController();
  final _certificationCtl = TextEditingController();
  final _detailsCtl = TextEditingController();

  final companyApi = CompanyApi();
  bool isSubmitting = false;
  bool isLoading = true;
  bool showForm = false;
  bool isEditing = false;
  String? editingPostId;
  List<dynamic> posts = [];

  double uniWeight = 0.0;
  double gpaWeight = 0.0;
  double certWeight = 0.0;
  double projWeight = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final data = await companyApi.fetchCompanyPosts();
      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading posts: $e");
      setState(() => isLoading = false);
    }
  }

  void _openForEdit(Map<String, dynamic> post) {
    setState(() {
      showForm = true;
      isEditing = true;
      editingPostId = post['_id'];
      _roleCtl.text = post['jobRole'] ?? '';
      _descCtl.text = post['description'] ?? '';
      _skillsCtl.text = post['skills'] ?? '';
      _certificationCtl.text = post['certifications'] ?? '';
      _detailsCtl.text = post['details'] ?? '';

      final weights = post['weights'] ?? {};
      uniWeight = (weights['university'] ?? 0) / 100.0;
      gpaWeight = (weights['gpa'] ?? 0) / 100.0;
      certWeight = (weights['certifications'] ?? 0) / 100.0;
      projWeight = (weights['projects'] ?? 0) / 100.0;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _roleCtl.clear();
    _descCtl.clear();
    _skillsCtl.clear();
    _certificationCtl.clear();
    _detailsCtl.clear();
    uniWeight = gpaWeight = certWeight = projWeight = 0.0;
    isEditing = false;
    editingPostId = null;
  }

  int get totalWeight =>
      ((uniWeight + gpaWeight + certWeight + projWeight) * 100).round();

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (totalWeight != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total weight must equal 100%")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final postData = {
      "jobRole": _roleCtl.text.trim(),
      "description": _descCtl.text.trim(),
      "skills": _skillsCtl.text.trim(),
      "certifications": _certificationCtl.text.trim(),
      "details": _detailsCtl.text.trim(),
      "weights": {
        "university": (uniWeight * 100).toInt(),
        "gpa": (gpaWeight * 100).toInt(),
        "certifications": (certWeight * 100).toInt(),
        "projects": (projWeight * 100).toInt(),
      },
      "companyName": widget.companyName,
      "companyReg": widget.companyReg,
      "companyLogo": widget.companyLogo,
    };

    bool success = false;
    if (isEditing && editingPostId != null) {
      success = await companyApi.updateJobPost(editingPostId!, postData);
    } else {
      success = await companyApi.createJobPost(postData);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing
            ? 'Job Post Updated Successfully!'
            : 'Job Post Added Successfully!'),
      ));
      await _loadPosts();
      _resetForm();
      setState(() => showForm = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing ? 'Failed to update post' : 'Failed to add post'),
      ));
    }

    setState(() => isSubmitting = false);
  }

  Future<void> _deletePost(String postId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this job post?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")),
        ],
      ),
    );
    if (!confirmed) return;

    bool success = await companyApi.deleteJobPost(postId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job post deleted successfully")));
      await _loadPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete job post")));
    }
  }

  void _onWeightChanged(String field, double value) {
    double totalBefore =
        uniWeight + gpaWeight + certWeight + projWeight - _getFieldValue(field);
    double newTotal = totalBefore + value;
    if (newTotal <= 1.0) {
      setState(() => _setFieldValue(field, value));
    }
  }

  double _getFieldValue(String field) {
    switch (field) {
      case 'uni':
        return uniWeight;
      case 'gpa':
        return gpaWeight;
      case 'cert':
        return certWeight;
      case 'proj':
        return projWeight;
      default:
        return 0.0;
    }
  }

  void _setFieldValue(String field, double value) {
    switch (field) {
      case 'uni':
        uniWeight = value;
        break;
      case 'gpa':
        gpaWeight = value;
        break;
      case 'cert':
        certWeight = value;
        break;
      case 'proj':
        projWeight = value;
        break;
    }
  }

  Widget buildWeightsBar(Map<String, dynamic> weights) {
    final labels = ["Uni.", "GPA", "Certi.", "Proj."];
    final keys = ["university", "gpa", "certifications", "projects"];
    final colors = [
      const Color(0xFF1F618D),
      const Color(0xFF2980B9),
      const Color(0xFF3498DB),
      const Color(0xFF48C9B0),
    ];

    final filtered = <Map<String, dynamic>>[];
    for (int i = 0; i < keys.length; i++) {
      final value = (weights[keys[i]] ?? 0);
      if (value > 0)
        filtered.add({'label': labels[i], 'value': value, 'color': colors[i]});
    }

    if (filtered.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: filtered.map((e) {
          final flex = (e['value'] as num).toInt();
          return Expanded(
            flex: flex,
            child: Container(
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: e['color'] as Color,
              ),
              child: Text(
                "${e['label']} (${e['value']}%)",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValidTotal = totalWeight == 100;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (showForm && isEditing) _resetForm();
            showForm = !showForm;
          });
        },
        backgroundColor: Colors.blue.shade700,
        child: Icon(
          showForm ? Icons.close : Icons.add,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // optional: rounded corners
          side: BorderSide(
            color: const Color.fromARGB(255, 255, 255, 255), // optional: add border if needed
            width: 0,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: showForm
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildFormCard(isValidTotal),
                    secondChild: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Your Job Posts",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  posts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "No job posts added yet.\nTap the '+' button to add one.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade700),
                            ),
                          ),
                        )
                      : Column(
                          children: posts.map((post) {
                            final weights = post['weights'] ?? {};
                            return _buildPostCard(post, weights);
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, String? content) {
  if (content == null || content.trim().isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildPostCard(Map<String, dynamic> post, Map<String, dynamic> weights) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        color: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(post['jobRole'] ?? 'No Role',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
              post['description'] ?? 'No Description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _openForEdit(post),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deletePost(post['_id']),
                ),
              ],
            ),
            children: [
              const Divider(),
              _buildSection("Description", post['description']),
              _buildSection("Required Skills", post['skills']),
              _buildSection("Certifications", post['certifications']),
              _buildSection("Other Details", post['details']),

              const SizedBox(height: 8),
              if (weights.isNotEmpty) buildWeightsBar(weights),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRowJustify(String title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.justify,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isValidTotal) {
  return Card(
    color: Colors.white, // <-- Add this line
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 12,
    shadowColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? "Edit Job Post" : "Create New Job Post",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTextField(_roleCtl, "Job Role"),
            _buildTextField(_descCtl, "Description", maxLines: 5),
            _buildTextField(_skillsCtl, "Required Skills", maxLines: 4),
            _buildTextField(_certificationCtl, "Certifications and Badges", maxLines: 4),
            _buildTextField(_detailsCtl, "Other Details", maxLines: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Criteria Weights (%)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "Total: $totalWeight%",
                    style: TextStyle(
                      color: isValidTotal ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _buildWeightSlider("University Ranking", uniWeight, (v) => _onWeightChanged('uni', v)),
              _buildWeightSlider("GPA Score", gpaWeight, (v) => _onWeightChanged('gpa', v)),
              _buildWeightSlider("Certifications", certWeight, (v) => _onWeightChanged('cert', v)),
              _buildWeightSlider("Projects", projWeight, (v) => _onWeightChanged('proj', v)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.send),
                  label: isSubmitting
                      ? const Text("Processing...")
                      : Text(isEditing ? "Save Changes" : "Submit Job Post"),
                  onPressed: (!isValidTotal || isSubmitting) ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctl, String label,
    {int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12), // less spacing between fields
    child: TextFormField(
      controller: ctl,
      maxLines: maxLines, // limit max lines
      minLines: 1,
      keyboardType: TextInputType.multiline,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, // reduce horizontal padding slightly
          // reduce vertical padding to make field shorter
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color.fromARGB(255, 235, 235, 235), width: 0.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
        ),
      ),
    ),
  );
}


  Widget _buildWeightSlider(
      String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${(value * 100).toInt()}%"),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 5,
          label: "${(value * 100).toInt()}%",
          onChanged: onChanged,
          activeColor: Colors.blue.shade700,
          thumbColor: Colors.blue.shade700,
        ),
      ],
    );
  }
}
