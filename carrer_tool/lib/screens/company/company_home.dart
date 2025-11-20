import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/company_api.dart';
import 'company_add_posts.dart';
import '../../services/auth_service.dart';
import 'company_home_body.dart';

/// --- Design Constants (matched to StudentHome) ---
const kPrimaryColor = Color(0xFF3B82F6);
const kAppBarColor = Color(0xFF1976D2);
const kBackgroundColor = Color(0xFFFCFCFD);
const kCardElevation = 4.0;

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
    setState(() => isLoading = true);
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

  Color selectedBlue = const Color.fromARGB(255, 59,130,246);

  @override
  Widget build(BuildContext context) {
    final name = companyData?['companyName'] ?? '';
    final regNo = companyData?['companyReg'] ?? '';
    final dis = companyData?['companyDis'] ?? '';
    final logoUrl = companyData?['companyLogo'] ?? '';
    final companyId = companyData?['_id'] ?? '';

    final pages = [
      CompanyHomeBody(
        companyName: name,
        companyReg: regNo,
        companyDis: dis,
        companyLogo: logoUrl,
        companyId: companyId,
        refreshParent: _loadProfile, // pass refresh callback
      ),
      CompanyAddPosts(
        companyName: name,
        companyReg: regNo,
        companyDis: dis,
        companyLogo: logoUrl,
        companyId: companyId,
      ),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          selectedIndex == 0 ? 'Company Dashboard' : 'Add Posts',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      drawer: Drawer(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryColor, kAppBarColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: logoUrl.isNotEmpty
                              ? NetworkImage(
                                  '$logoUrl?v=${DateTime.now().millisecondsSinceEpoch}', // cache-busting
                                )
                              : null,
                          child: logoUrl.isEmpty
                              ? const Icon(Icons.business, size: 36)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text(
                          "Reg No: $regNo",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _drawerItem(Icons.home, "Home", 0),
                        _drawerItem(Icons.add_box_outlined, "Add Posts", 1),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[selectedIndex],
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? selectedBlue : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? selectedBlue : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  // Transparent Card with Blur for Job Details (StudentHome style)
  Widget buildJobCard(Map<String, dynamic> job, {required Function() onViewRank}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job['jobRole'] ?? "Unknown Role",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(job['companyName'] ?? "Unknown Company",
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 12),
              if (job['description'] != null)
                Text(job['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 12),
              if (job['weights'] != null) buildWeightBar(job['weights']),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: onViewRank,
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  label: const Text(
                    "View Rank",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWeightBar(Map<String, dynamic> weights) {
    final List<Map<String, dynamic>> segments = [
      {"label": "Uni", "value": weights['university'] ?? 0, "color": kPrimaryColor},
      {"label": "GPA", "value": weights['gpa'] ?? 0, "color": Colors.blue.shade400},
      {"label": "Certi", "value": weights['certifications'] ?? 0, "color": Colors.cyan.shade300},
      {"label": "Proj", "value": weights['projects'] ?? 0, "color": Colors.teal.shade400},
    ];

    final filtered = segments.where((s) => (s['value'] ?? 0) > 0).toList();
    final total = filtered.fold<num>(0, (sum, s) => sum + (s['value'] ?? 0));
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: filtered.map((s) {
          final flexValue = ((s['value'] ?? 0) * 100 ~/ total).clamp(1, 100);
          return Flexible(
            flex: flexValue,
            child: Container(
              decoration: BoxDecoration(
                color: s['color'],
                borderRadius: BorderRadius.horizontal(
                  left: s == filtered.first ? const Radius.circular(12) : Radius.zero,
                  right: s == filtered.last ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                "${s['label']} ${s['value']}%",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
