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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      "Skills",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add the skills you are good at. Tap + to add each skill.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Skill Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _skillCtl,
                            decoration: InputDecoration(
                              hintText: "Enter a skill",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                              ),
                            ),
                            onSubmitted: (_) => addSkill(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: addSkill,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Skills Display
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .asMap()
                          .entries
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blueGrey.shade100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => removeSkill(e.key),
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (skills.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          "No skills added yet",
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Finish Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 3,
                    shadowColor: Colors.blueAccent.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: saveAndFinish,
                  child: const Text(
                    "Finish",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: Colors.white,
                    ),
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
