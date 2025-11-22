import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_onboarding_provider.dart';
import 'widgets/add_education_card.dart';

class EducationScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack; // Added back callback

  const EducationScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> _educationList = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);

    // Load previously saved education if exists
    if (provider.education.isNotEmpty) {
      for (var edu in provider.education) {
        _educationList.add({
          "school": TextEditingController(text: edu["school"] ?? ""),
          "degree": TextEditingController(text: edu["degree"] ?? ""),
          "field": TextEditingController(text: edu["field"] ?? ""),
          "gpa": TextEditingController(text: edu["gpa"] ?? ""),
          "description": TextEditingController(text: edu["description"] ?? ""),
          "year": TextEditingController(text: edu["year"] ?? ""),
          "startMonth": TextEditingController(text: edu["startMonth"] ?? ""),
          "startYear": TextEditingController(text: edu["startYear"] ?? ""),
          "endMonth": TextEditingController(text: edu["endMonth"] ?? ""),
          "endYear": TextEditingController(text: edu["endYear"] ?? ""),
        });
      }
    }

    // If no previous education, add one empty
    if (_educationList.isEmpty) {
      _educationList.add(_createEmptyEducation());
    }
  }

  Map<String, TextEditingController> _createEmptyEducation() => {
        "school": TextEditingController(),
        "degree": TextEditingController(),
        "field": TextEditingController(),
        "gpa": TextEditingController(),
        "description": TextEditingController(),
        "year": TextEditingController(),
        "startMonth": TextEditingController(),
        "startYear": TextEditingController(),
        "endMonth": TextEditingController(),
        "endYear": TextEditingController(),
      };

  void _addEducation() {
    setState(() {
      _educationList.add(_createEmptyEducation());
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _educationList.removeAt(index);
    });
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
    final data = _educationList.map((e) => {
          "school": e["school"]!.text.trim(),
          "degree": e["degree"]!.text.trim(),
          "field": e["field"]!.text.trim(),
          "gpa": e["gpa"]!.text.trim(),
          "description": e["description"]!.text.trim(),
          "year": e["year"]!.text.trim(),
          "startMonth": e["startMonth"]!.text.trim(),
          "startYear": e["startYear"]!.text.trim(),
          "endMonth": e["endMonth"]!.text.trim(),
          "endYear": e["endYear"]!.text.trim(),
        }).toList();

    provider.setEducation(data);
    widget.onNext(); // move forward
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBack, // use wrapper's back
        ),
        title: const Text(
          "Education",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Education",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add your educational background. You can add multiple entries.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      // Animated Education Cards
                      for (int i = 0; i < _educationList.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AddEducationCard(
                            school: _educationList[i]["school"]!,
                            degree: _educationList[i]["degree"]!,
                            field: _educationList[i]["field"]!,
                            gpa: _educationList[i]["gpa"]!,
                            description: _educationList[i]["description"]!,
                            year: _educationList[i]["year"]!,
                            startMonth: _educationList[i]["startMonth"]!,
                            startYear: _educationList[i]["startYear"]!,
                            endMonth: _educationList[i]["endMonth"]!,
                            endYear: _educationList[i]["endYear"]!,
                            onRemove: () => _removeEducation(i),
                            requireValidation: true,
                          ),
                        ),

                      // Add Education Button
                      Center(
                        child: TextButton.icon(
                          onPressed: _addEducation,
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF3B82F6)),
                          label: const Text(
                            "Add Education",
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Next Button fixed
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveAndNext,
                    child: const Text(
                      "Next",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
