import 'package:carrer_tool/screens/company/company_home_body.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/student_onboarding_provider.dart';

import 'screens/auth/sign_in.dart';
import 'screens/auth/sign_up.dart';
import 'screens/auth/forgot.dart';
import 'screens/company/company_home.dart';
import 'screens/student/student_home.dart';
import 'screens/student/onboarding/onboarding_wrapper.dart';
import 'screens/student/rank_result_screen.dart';
import 'screens/student/user_profile_screen.dart';
//import 'screens/student/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentOnboardingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// main.dart
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      navigatorObservers: [routeObserver], // <-- required
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      

      // First screen
      home: SignInScreen(),

      // Routes
      routes: {
        '/signin': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/forgot': (context) => ForgotScreen(),

        // ✅ Student Home — get userId from arguments
        '/student/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final userId = args?['userId'];
          if (userId == null) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing userId")),
            );
          }
          return StudentHome(userId: userId);
        },

        // Company Home
        '/company/home': (context) => CompanyLayout(),

        // Onboarding
        '/onboarding/student': (context) => const OnboardingWrapper(),

        '/student/rank': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;

          final userId = args?['userId'];
          final companyName = args?['companyName'];
          final jobRole = args?['jobRole'];
          final jobPostId = args?['jobPostId'];
          final weights = args?['weights'];

          if (userId == null || companyName == null || jobRole == null) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing required arguments")),
            );
          }

          return RankResultScreen(
            userId: userId,
            companyName: companyName,
            jobRole: jobRole,
            jobPostId: jobPostId,
            weights: weights,
          );
        },


        '/student/profiles': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final userId = args?['userId'];
          final jobPostId = args?['jobPostId'];

          if (userId == null) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing userId")),
            );
          }

          return UserProfileScreen(userId: userId, jobPostId: jobPostId,);
},

      },
    );
  }
}
