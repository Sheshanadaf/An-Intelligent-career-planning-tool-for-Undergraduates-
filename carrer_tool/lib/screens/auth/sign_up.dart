import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/scheduler.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  String _role = 'student';
  bool _loading = false;
  final auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _ugNameCtl = TextEditingController();
  final _ugEmailCtl = TextEditingController();
  final _ugPassCtl = TextEditingController();
  final _ugPhoneCtl = TextEditingController();

  final _companyNameCtl = TextEditingController();
  final _companyEmailCtl = TextEditingController();
  final _companyPassCtl = TextEditingController();
  final _companyRegCtl = TextEditingController();
  final _companyDisCtl = TextEditingController();

  File? _companyLogo;
  final ImagePicker _picker = ImagePicker();

  bool _showUgPassword = false;
  bool _showCompanyPassword = false;

  bool _passwordFieldFocusedUndergrad = false;
  bool _passwordFieldFocusedCompany = false;

  // Animation Controllers for Micro-interactions
  late final AnimationController _roleSwitchController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));

  Map<String, bool> _passwordRules(String password) {
    return {
      "More than 8 characters": password.length > 8,
      "At least 1 uppercase letter": RegExp(r'[A-Z]').hasMatch(password),
      "At least 1 lowercase letter": RegExp(r'[a-z]').hasMatch(password),
      "At least 1 number": RegExp(r'[0-9]').hasMatch(password),
      "At least 1 underscore (_)" : RegExp(r'_').hasMatch(password),
    };
  }

  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length <= 8) return 'Password must be more than 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Include at least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Include at least 1 lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Include at least 1 number';
    if (!RegExp(r'_').hasMatch(password)) return 'Include at least 1 underscore';
    return null;
  }

  Future<void> _pickCompanyLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _companyLogo = File(image.path));
  }

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
          companyDis: _companyDisCtl.text.trim(),
          companyLogo: _companyLogo,
        );
        await auth.login(_companyEmailCtl.text.trim(), _companyPassCtl.text);
        Navigator.pushNamedAndRemoveUntil(context, '/company/home', (_) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _textField({
  required TextEditingController controller,
  required String label,
  IconData? icon, // <-- add icon parameter
  bool obscure = false,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  VoidCallback? onToggle,
  void Function(String)? onChanged,
  void Function(bool)? onFocusChange,
  int? minLines = 1,
  int? maxLines = 1,
}) {
  return Focus(
    onFocusChange: (focused) {
      if (onFocusChange != null) onFocusChange(focused);
      setState(() {});
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6), // <-- reduced spacing
      transform: Matrix4.identity()..scale(1.0, 1.0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        style: TextStyle(color: Colors.grey[900], fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
                  onPressed: onToggle)
              : null,
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[400]),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      ),
    ),
  );
}


  Widget _passwordRulesWidget(String password, bool show) {
    final rules = _passwordRules(password);
    if (!show) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rules.entries.map((e) {
            return Row(
              children: [
                Icon(
                  e.value ? Icons.check_circle : Icons.cancel,
                  color: e.value ? Colors.green : Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  e.key,
                  style: TextStyle(fontSize: 12, color: e.value ? Colors.green : Colors.redAccent),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _roleSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildRoleButton("Undergraduate", "student"),
          _buildRoleButton("Company", "company"),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String label, String value) {
    final bool selected = _role == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _role = value);
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _undergraduateFields() {
    return Column(
      children: [
        _textField(controller: _ugNameCtl, label: "Full Name", icon: Icons.person_outline),
        _textField(controller: _ugEmailCtl, label: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        _textField(
          controller: _ugPassCtl,
          label: "Password",
          obscure: !_showUgPassword,
          icon: Icons.lock_outline,
          validator: _validatePassword,
          onToggle: () => setState(() => _showUgPassword = !_showUgPassword),
          onChanged: (value) => setState(() {}),
          onFocusChange: (focused) => setState(() => _passwordFieldFocusedUndergrad = focused),
        ),
        _passwordRulesWidget(_ugPassCtl.text, _passwordFieldFocusedUndergrad),
        _textField(controller: _ugPhoneCtl, label: "Phone Number", icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _companyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
            controller: _companyNameCtl,
            label: "Company Name",
            icon: Icons.business_outlined, // suitable icon for company name
          ),
          _textField(
            controller: _companyEmailCtl,
            label: "Email",
            icon: Icons.email_outlined, // email icon
            keyboardType: TextInputType.emailAddress,
          ),
          _textField(
            controller: _companyPassCtl,
            label: "Password",
            icon: Icons.lock_outline, // password lock icon
            obscure: !_showCompanyPassword,
            validator: _validatePassword,
            onToggle: () => setState(() => _showCompanyPassword = !_showCompanyPassword),
            onChanged: (value) => setState(() {}),
            onFocusChange: (focused) => setState(() => _passwordFieldFocusedCompany = focused),
          ),
          _passwordRulesWidget(_companyPassCtl.text, _passwordFieldFocusedCompany),
          _textField(
            controller: _companyRegCtl,
            label: "Company Reg. Number", 
          ),
        _textField(
          controller: _companyDisCtl,
          label: "Description",
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: null,
        ),
        const SizedBox(height: 20),
        const Text("Company Logo (Optional)", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCompanyLogo,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: _companyLogo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_companyLogo!, fit: BoxFit.cover),
                  )
                : const Center(child: Icon(Icons.camera_alt, color: Colors.grey, size: 32)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Account Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _roleSelector(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: Offset(_role == 'student' ? 1 : -1, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(position: offsetAnimation, child: FadeTransition(opacity: animation, child: child));
                  },
                  child: _role == 'student' ? _undergraduateFields() : _companyFields(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: const Color(0xFF3B82F6),
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Continue",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
