import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String _role = 'student';
  bool _loading = false;
  final auth = AuthService();

  final _formKey = GlobalKey<FormState>();

  // ---------- Controllers ----------
  final _ugNameCtl = TextEditingController();
  final _ugEmailCtl = TextEditingController();
  final _ugPassCtl = TextEditingController();
  final _ugPhoneCtl = TextEditingController();

  final _companyNameCtl = TextEditingController();
  final _companyEmailCtl = TextEditingController();
  final _companyPassCtl = TextEditingController();
  final _companyRegCtl = TextEditingController();

  File? _companyLogo;
  final ImagePicker _picker = ImagePicker();

  bool _showUgPassword = false;
  bool _showCompanyPassword = false;
  double _passwordStrength = 0;

  // ---------- PICK IMAGE ----------
  Future<void> _pickCompanyLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _companyLogo = File(image.path));
  }

  // ---------- VALIDATION ----------
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number required';
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Enter valid phone number';
    return null;
  }

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      _passwordStrength = 0;
    } else if (password.length < 6) {
      _passwordStrength = 0.25;
    } else if (RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      _passwordStrength = 0.6;
    } else if (RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])').hasMatch(password)) {
      _passwordStrength = 1.0;
    } else {
      _passwordStrength = 0.4;
    }
    setState(() {});
  }

  // ---------- REGISTER ----------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_role == 'student') {
        await auth.register(
          name: _ugNameCtl.text.trim(),
          email: _ugEmailCtl.text.trim(),
          password: _ugPassCtl.text,
          role: _role,
          phone: _ugPhoneCtl.text.trim(),
        );
        await auth.login(_ugEmailCtl.text.trim(), _ugPassCtl.text);
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding/student', (_) => false);
      } else {
        await auth.register(
          name: _companyNameCtl.text.trim(),
          email: _companyEmailCtl.text.trim(),
          password: _companyPassCtl.text,
          role: _role,
          companyName: _companyNameCtl.text.trim(),
          companyReg: _companyRegCtl.text.trim(),
          companyLogo: _companyLogo,
        );
        await auth.login(_companyEmailCtl.text.trim(), _companyPassCtl.text);
        Navigator.pushNamedAndRemoveUntil(context, '/company/home', (_) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------- REUSABLE TEXT FIELD ----------
  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    VoidCallback? onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        onChanged: (value) {
          if (label == "Password") _checkPasswordStrength(value);
        },
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onToggle,
                )
              : null,
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
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      ),
    );
  }

  // ---------- PASSWORD STRENGTH BAR ----------
  Widget _passwordStrengthBar() {
    Color color;
    String label;

    if (_passwordStrength <= 0.25) {
      color = Colors.redAccent;
      label = "Weak";
    } else if (_passwordStrength <= 0.5) {
      color = Colors.orangeAccent;
      label = "Fair";
    } else if (_passwordStrength < 1) {
      color = Colors.lightGreen;
      label = "Good";
    } else {
      color = Colors.green;
      label = "Strong";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _passwordStrength,
          color: color,
          backgroundColor: Colors.grey[300],
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 4),
        Text(
          "Password strength: $label",
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _undergraduateFields() {
    return Column(
      children: [
        _textField(controller: _ugNameCtl, label: "Full Name", icon: Icons.person),
        _textField(
          controller: _ugEmailCtl,
          label: "Email",
          icon: Icons.email_outlined,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        _textField(
          controller: _ugPassCtl,
          label: "Password",
          icon: Icons.lock_outline,
          obscure: !_showUgPassword,
          validator: _validatePassword,
          onToggle: () => setState(() => _showUgPassword = !_showUgPassword),
        ),
        _passwordStrengthBar(),
        _textField(
          controller: _ugPhoneCtl,
          label: "Phone Number",
          icon: Icons.phone,
          validator: _validatePhone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _companyFields() {
    return Column(
      children: [
        _textField(controller: _companyNameCtl, label: "Company Name", icon: Icons.business),
        _textField(
          controller: _companyEmailCtl,
          label: "Email",
          icon: Icons.email_outlined,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        _textField(
          controller: _companyPassCtl,
          label: "Password",
          icon: Icons.lock_outline,
          obscure: !_showCompanyPassword,
          validator: _validatePassword,
          onToggle: () => setState(() => _showCompanyPassword = !_showCompanyPassword),
        ),
        _passwordStrengthBar(),
        _textField(controller: _companyRegCtl, label: "Company Reg. Number", icon: Icons.confirmation_number),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: const Text("Company Logo (Optional)", style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCompanyLogo,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _companyLogo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_companyLogo!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.camera_alt, size: 36, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Account Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'student', label: Text("Undergraduate")),
                    ButtonSegment(value: 'company', label: Text("Company")),
                  ],
                  selected: {_role},
                  onSelectionChanged: (value) => setState(() => _role = value.first),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _role == 'student' ? _undergraduateFields() : _companyFields(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
