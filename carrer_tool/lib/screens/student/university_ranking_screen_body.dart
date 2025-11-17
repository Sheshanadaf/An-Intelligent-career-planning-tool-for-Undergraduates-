// lib/screens/student/university_ranking_screen_body.dart
import 'package:flutter/material.dart';
import '../../services/university_ranking_api.dart';

class UniversityRankingScreenBody extends StatefulWidget {
  final String userId;

  const UniversityRankingScreenBody({super.key, required this.userId});

  @override
  State<UniversityRankingScreenBody> createState() =>
      _UniversityRankingScreenBodyState();
}

class _UniversityRankingScreenBodyState
    extends State<UniversityRankingScreenBody> {
  final UniversityRankingService _service = UniversityRankingService();
  List<Map<String, dynamic>> _rankings = [];
  bool _loading = true;

  bool get isAdmin => widget.userId == "690ce41a9086b856f32ff6e0";

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  // ✅ Fetch data
  Future<void> _fetchRankings() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchRankings();
      setState(() {
        _rankings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  // ✅ Show Add/Edit Dialog
  void _showAddOrEditDialog({Map<String, dynamic>? existing}) {
    final nameController =
        TextEditingController(text: existing?['name'] ?? '');
    final rankController =
        TextEditingController(text: existing?['rank']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? "Add University" : "Edit University"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "University Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rankController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Ranking",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final rank = int.tryParse(rankController.text.trim());

                if (name.isEmpty || rank == null) {
                  _showError("Please fill all fields correctly.");
                  return;
                }

                Navigator.pop(context);
                await _saveUniversity(name, rank, existing?['_id']);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Add / Update
  Future<void> _saveUniversity(String name, int rank, [String? id]) async {
    try {
      if (id != null) {
        await _service.updateRanking(id, name, rank);
        _showSuccess("✅ University updated successfully!");
      } else {
        await _service.addRanking(name, rank);
        _showSuccess("✅ University added successfully!");
      }

      await _fetchRankings();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ✅ Delete
  Future<void> _deleteUniversity(String id) async {
    try {
      await _service.deleteRanking(id);
      _showSuccess("🗑️ University deleted successfully!");
      await _fetchRankings();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ✅ Error + Success helpers
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst("Exception: ", "❌ ")),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddOrEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text("Add University"),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rankings.isEmpty
              ? const Center(
                  child: Text(
                    "No university rankings added yet.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _rankings.length,
                    itemBuilder: (context, index) {
                      final uni = _rankings[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              uni['rank'].toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            uni['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.orange),
                                      onPressed: () =>
                                          _showAddOrEditDialog(existing: uni),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteUniversity(uni['_id']),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
