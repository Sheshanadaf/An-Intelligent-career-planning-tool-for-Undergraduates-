import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final auth = AuthService();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _checkExistingSession();
  }

  Future<void> _loadRememberedCredentials() async {
  // 🔍 Directly read from storage for debugging
  final savedEmail = await auth.storage.read(key: 'savedEmail');
  final savedPassword = await auth.storage.read(key: 'savedPassword');
  debugPrint("🔍 Read directly from storage: $savedEmail / $savedPassword");

  // Existing method
  final creds = await auth.getSavedCredentials();
  if (creds != null) {
    setState(() {
      _emailCtl.text = creds["email"]!;
      _passCtl.text = creds["password"]!;
      _rememberMe = true;
    });
  }
  debugPrint("Loaded credentials from getSavedCredentials(): $creds");
}


  Future<void> _checkExistingSession() async {
    final session = await auth.restoreUserSession();
    if (session != null) {
      final role = session['role'];
      final userId = session['userId'];
      if (role == 'company') {
        Navigator.pushReplacementNamed(context, '/company/home');
      } else {
        Navigator.pushReplacementNamed(context, '/student/home',
            arguments: {'userId': userId});
      }
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await auth.login(_emailCtl.text.trim(), _passCtl.text);

      if (_rememberMe) {
        await auth.saveLoginCredentials(_emailCtl.text, _passCtl.text);
        final testEmail = await auth.storage.read(key: 'savedEmail');
        final testPass = await auth.storage.read(key: 'savedPassword');
        debugPrint("🔍 Immediately after saving: $testEmail / $testPass");
      } else {
        await auth.clearSavedCredentials();
      }

      final role = await auth.getRole();
      final userId = await auth.getUserId();

      if (userId == null || userId.isEmpty) {
        _showSnack("Login failed. User ID not found.");
        return;
      }

      if (role == 'company') {
        Navigator.pushReplacementNamed(context, '/company/home');
      } else {
        Navigator.pushReplacementNamed(context, '/student/home',
            arguments: {'userId': userId});
      }
    } catch (e) {
      _showSnack("Login failed. Check your credentials.");
      debugPrint("Login error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Email cannot be empty.";
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) return "Enter a valid email.";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password cannot be empty.";
    if (value.length < 6) return "Password must be at least 6 characters.";
    return null;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    required TextInputAction inputAction,
    IconData? icon,
    bool obscure = false,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        textInputAction: inputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        autofillHints: label == "Email"
            ? [AutofillHints.username, AutofillHints.email]
            : [AutofillHints.password],
        keyboardType:
            label == "Email" ? TextInputType.emailAddress : TextInputType.text,
        enableSuggestions: true,
        autocorrect: false,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
          suffixIcon: label == "Password"
              ? IconButton(
                  icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text("Welcome Back",
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                  const SizedBox(height: 8),
                  Text("Sign in to continue your journey",
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280))),
                  const SizedBox(height: 36),

                  AutofillGroup(
                    child: Column(
                      children: [
                        _textField(
                          controller: _emailCtl,
                          label: "Email",
                          icon: Icons.email,
                          focusNode: _emailFocus,
                          inputAction: TextInputAction.next,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passFocus),
                        ),
                        _textField(
                          controller: _passCtl,
                          label: "Password",
                          icon: Icons.lock,
                          focusNode: _passFocus,
                          inputAction: TextInputAction.done,
                          obscure: _obscurePassword,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _login(),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val ?? false),
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Sign In",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot'),
                      child: const Text("Forgot password?",
                          style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text("Sign Up",
                            style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
