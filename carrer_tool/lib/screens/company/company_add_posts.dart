import 'package:flutter/material.dart';
import 'services/company_api.dart';

class CompanyAddPosts extends StatefulWidget {
  final String companyName;
  final String companyReg;
  final String? companyLogo;

  const CompanyAddPosts({
    super.key,
    required this.companyName,
    required this.companyReg,
    this.companyLogo,
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
      print("❌ Error loading posts: $e");
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
    };

    bool success = false;
    if (isEditing && editingPostId != null) {
      success = await companyApi.updateJobPost(editingPostId!, postData);
    } else {
      success = await companyApi.createJobPost(postData);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            isEditing ? 'Job Post Updated Successfully!' : 'Job Post Added Successfully!'),
      ));
      await _loadPosts();
      _resetForm();
      setState(() => showForm = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing
            ? 'Failed to update post'
            : 'Failed to add post'),
      ));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isValidTotal = totalWeight == 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Job Posts'),
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(showForm ? Icons.close : Icons.add),
        label: Text(showForm
            ? (isEditing ? "Cancel Edit" : "Close Form")
            : "Add Job Post"),
        onPressed: () {
          setState(() {
            if (showForm && isEditing) _resetForm();
            showForm = !showForm;
          });
        },
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
                  const SizedBox(height: 25),
                  const Text(
                    "Your Job Posts",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  posts.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "No job posts added yet.\nTap the '+' button to add one.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      : Column(
                          children: posts.map((post) {
                            final weights = post['weights'] ?? {};
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                tilePadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Text(
                                  post['jobRole'] ?? 'No Role',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                  post['description'] ?? 'No Description',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent),
                                  onPressed: () => _openForEdit(post),
                                ),
                                children: [
                                  const Divider(),
                                  _buildInfoRow(
                                      "Description", post['description']),
                                  _buildInfoRow("Skills", post['skills']),
                                  _buildInfoRow("Certifications",
                                      post['certifications']),
                                  _buildInfoRow("Other Details",
                                      post['details']),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Criteria Weights:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "University: ${weights['university'] ?? 0}%\n"
                                    "GPA: ${weights['gpa'] ?? 0}%\n"
                                    "Certifications: ${weights['certifications'] ?? 0}%\n"
                                    "Projects: ${weights['projects'] ?? 0}%",
                                    style: const TextStyle(height: 1.4),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormCard(bool isValidTotal) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? "Edit Job Post" : "Create New Job Post",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildTextField(_roleCtl, "Job Role"),
              _buildTextField(_descCtl, "Description", maxLines: 3),
              _buildTextField(_skillsCtl, "Required Skills"),
              _buildTextField(_certificationCtl, "Certifications and Badges"),
              _buildTextField(_detailsCtl, "Other Details", maxLines: 2),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Criteria Weights (%)",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              const SizedBox(height: 10),
              _buildWeightSlider("University Ranking", uniWeight,
                  (v) => _onWeightChanged('uni', v)),
              _buildWeightSlider("GPA Score", gpaWeight,
                  (v) => _onWeightChanged('gpa', v)),
              _buildWeightSlider("Certifications", certWeight,
                  (v) => _onWeightChanged('cert', v)),
              _buildWeightSlider("Projects", projWeight,
                  (v) => _onWeightChanged('proj', v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.send),
                  label: isSubmitting
                      ? const Text("Processing...")
                      : Text(isEditing ? "Save Changes" : "Submit Job Post"),
                  onPressed:
                      (!isValidTotal || isSubmitting) ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onWeightChanged(String field, double value) {
    double totalBefore =
        uniWeight + gpaWeight + certWeight + projWeight - _getFieldValue(field);
    double newTotal = totalBefore + value;

    // Prevent total > 1.0 (100%)
    if (newTotal <= 1.0) {
      setState(() {
        _setFieldValue(field, value);
      });
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

  Widget _buildTextField(TextEditingController ctl, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctl,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey)),
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
        ),
      ],
    );
  }
}

Widget _buildInfoRow(String title, String? value) {
  if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(
            text: "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}
