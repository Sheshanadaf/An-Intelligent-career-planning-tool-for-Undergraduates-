import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_onboarding_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  final VoidCallback onNext;
  const PersonalInfoScreen({super.key, required this.onNext});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  final _locationCtl = TextEditingController();

  File? _profilePic;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profilePic = File(picked.path));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo selected successfully")),
      );
    }
  }

  void savePersonalInfo() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
    provider.setPersonalInfo(
      name: _nameCtl.text.trim(),
      bio: _bioCtl.text.trim(),
      location: _locationCtl.text.trim(),
      imageFile: _profilePic,
    );
    widget.onNext();
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tell us about yourself",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add a few details to set up your profile. You can always edit later.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),

                _textField(
                  controller: _nameCtl,
                  label: "Full Name",
                  validator: (v) => v == null || v.isEmpty ? "Name is required" : null,
                ),
                _textField(
                  controller: _bioCtl,
                  label: "Bio",
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? "Bio is required" : null,
                ),
                _textField(
                  controller: _locationCtl,
                  label: "Location",
                  validator: (v) => v == null || v.isEmpty ? "Location is required" : null,
                ),

                // 👇 Circular Profile Image Section
                const SizedBox(height: 20),
                const Text(
                  "Profile Picture (Optional)",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),

                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            boxShadow: _profilePic != null
                                ? [
                                    BoxShadow(
                                      color: Colors.black26.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: _profilePic == null
                              ? const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : ClipOval(
                                  child: Image.file(
                                    _profilePic!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _profilePic == null
                              ? "Tap to upload"
                              : "Tap to change photo",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: savePersonalInfo,
                    child: const Text(
                      "Next",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
