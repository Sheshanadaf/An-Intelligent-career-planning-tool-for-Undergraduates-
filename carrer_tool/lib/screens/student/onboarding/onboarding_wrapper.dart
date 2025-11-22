// lib/screens/student/onboarding/onboarding_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../providers/student_onboarding_provider.dart';
import 'personal_info.dart';
import 'education.dart';
import 'skills.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

final auth = AuthService();

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  int _step = 0; // 0=Personal,1=Education,2=Skills
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      PersonalInfoScreen(onNext: next),
      EducationScreen(onNext: next, onBack: back),
      SkillsScreen(onFinish: goHome, onBack: back),
    ];
  }

  void next() {
    if (_step < pages.length - 1) setState(() => _step++);
  }

  void back() {
    if (_step > 0) setState(() => _step--);
  }

  void goHome() async {
    final userId = await auth.getUserId();
    if (userId == null || userId.isEmpty) {
      debugPrint("⚠️ UserId not found");
      return;
    }

    Navigator.pushReplacementNamed(context, '/student/home', arguments: {
      'userId': userId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentOnboardingProvider(),
      child: Scaffold(
        body: WillPopScope(
          onWillPop: () async {
            if (_step == 0) return false;
            back();
            return false;
          },
          child: IndexedStack(
            index: _step,
            children: pages,
          ),
        ),
      ),
    );
  }
}
