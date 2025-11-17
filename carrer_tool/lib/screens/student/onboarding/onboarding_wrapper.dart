import 'package:flutter/material.dart';
import 'personal_info.dart';
import 'education.dart';
import 'skills.dart';
import '../../../services/auth_service.dart'; 


class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

final auth = AuthService();


class _OnboardingWrapperState extends State<OnboardingWrapper> {
  int _step = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      PersonalInfoScreen(onNext: next),
      EducationScreen(onNext: next),
      SkillsScreen(onFinish: goHome),
    ];
  }

  void next() => setState(() => _step++);
  void back() => setState(() => _step--);

  void goHome() async {
  final userId = await auth.getUserId(); // ✅ await because it's Future

  if (userId == null || userId.isEmpty) {
    debugPrint("⚠️ UserId is null — user not logged in or not saved $userId");
    return;
  }

  Navigator.pushReplacementNamed(
    context,
    '/student/home',
    arguments: {'userId': userId},
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_step],
    );
  }
}
