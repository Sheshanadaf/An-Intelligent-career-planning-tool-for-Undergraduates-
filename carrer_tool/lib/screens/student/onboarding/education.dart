import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_onboarding_provider.dart';
import 'widgets/add_education_card.dart';

class EducationScreen extends StatefulWidget {
  final VoidCallback onNext;
  const EducationScreen({super.key, required this.onNext});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, TextEditingController>> educationList = [
    {
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
    }
  ];

  void _addEducation() {
    setState(() {
      educationList.add({
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
      });
    });
  }

  void _removeEducation(int index) {
    setState(() {
      educationList.removeAt(index);
    });
  }

  void saveAndNext() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);

    final data = educationList.map((e) => {
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
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Education",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Education Cards
                      for (int i = 0; i < educationList.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AddEducationCard(
                            school: educationList[i]["school"]!,
                            degree: educationList[i]["degree"]!,
                            field: educationList[i]["field"]!,
                            gpa: educationList[i]["gpa"]!,
                            description: educationList[i]["description"]!,
                            year: educationList[i]["year"]!,
                            startMonth: educationList[i]["startMonth"]!,
                            startYear: educationList[i]["startYear"]!,
                            endMonth: educationList[i]["endMonth"]!,
                            endYear: educationList[i]["endYear"]!,
                            onRemove: () => _removeEducation(i),
                            requireValidation: true,
                          ),
                        ),

                      // Add Education Button
                      Center(
                        child: TextButton.icon(
                          onPressed: _addEducation,
                          icon: const Icon(Icons.add, color: Color(0xFF3B82F6)),
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

              // Next Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    onPressed: saveAndNext,
                    child: const Text(
                      "Next",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
