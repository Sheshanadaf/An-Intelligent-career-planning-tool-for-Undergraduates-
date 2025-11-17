import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_onboarding_provider.dart';
import 'widgets/skill_chip.dart';

class SkillsScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SkillsScreen({super.key, required this.onFinish});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final TextEditingController _skillCtl = TextEditingController();
  List<String> skills = [];

  void addSkill() {
    final skill = _skillCtl.text.trim();
    if (skill.isEmpty || skills.contains(skill)) return;
    setState(() => skills.add(skill));
    _skillCtl.clear();
  }

  void removeSkill(int i) {
    setState(() => skills.removeAt(i));
  }

  void saveAndFinish() async {
    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
    provider.setSkills(skills);

    bool ok = await provider.submitProfile();
    if (ok) {
      widget.onFinish();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit profile")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Skills",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add the skills you are good at. Tap + to add each skill.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Skill input
                    TextField(
                      controller: _skillCtl,
                      decoration: InputDecoration(
                        labelText: "Add Skill",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          onPressed: addSkill,
                          icon: const Icon(Icons.add, color: Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skills display
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < skills.length; i++)
                          SkillChip(
                            text: skills[i],
                            onDelete: () => removeSkill(i),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Finish button
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
                  onPressed: saveAndFinish,
                  child: const Text(
                    "Finish",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
