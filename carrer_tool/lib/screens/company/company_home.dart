import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/company_api.dart';
import 'company_add_posts.dart';
import '../../services/auth_service.dart';
import 'company_home_body.dart';

class CompanyLayout extends StatefulWidget {
  const CompanyLayout({super.key});

  @override
  State<CompanyLayout> createState() => _CompanyLayoutState();
}

class _CompanyLayoutState extends State<CompanyLayout> {
  final storage = const FlutterSecureStorage();
  final companyApi = CompanyApi();
  final auth = AuthService();

  Map<String, dynamic>? companyData;
  bool isLoading = true;
  int selectedIndex = 0; // 0 = Home, 1 = Add Posts

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await companyApi.fetchCompanyProfile();
    setState(() {
      companyData = data;
      isLoading = false;
    });
  }

  void _logout() async {
    await auth.logout();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final name = companyData?['companyName'] ?? '';
    final regNo = companyData?['companyReg'] ?? '';
    final logoUrl = companyData?['companyLogo'] ?? '';

    final pages = [
      CompanyHomeBody(
        companyName: name,
        companyReg: regNo,
        companyLogo: logoUrl,
      ),
      CompanyAddPosts(
        companyName: name,
        companyReg: regNo,
        companyLogo: logoUrl,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedIndex == 0 ? 'Company Dashboard' : 'Add Posts'),
      ),
      drawer: Drawer(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.blueAccent),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: logoUrl.isNotEmpty
                              ? NetworkImage(logoUrl)
                              : null,
                          child: logoUrl.isEmpty
                              ? const Icon(Icons.business, size: 35)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Reg No: $regNo",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    selected: selectedIndex == 0,
                    onTap: () {
                      setState(() => selectedIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_box_outlined),
                    title: const Text('Add Posts'),
                    selected: selectedIndex == 1,
                    onTap: () {
                      setState(() => selectedIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[selectedIndex],
    );
  }
}
