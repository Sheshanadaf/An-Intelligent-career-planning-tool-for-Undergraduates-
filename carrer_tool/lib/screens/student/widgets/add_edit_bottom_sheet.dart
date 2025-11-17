import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_onboarding_provider.dart';

Future<void> showAddEditBottomSheet(
  BuildContext context,
  String type, {
  Map<String, dynamic>? existingData,
  int? index,
}) async {
  final provider = Provider.of<StudentOnboardingProvider>(context, listen: false);
  final formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> controllers = {};

  // -------------------- Define Fields --------------------
  switch (type) {
    case "licenses":
      controllers = {
        "name": TextEditingController(text: existingData?["name"] ?? ""),
        "organization": TextEditingController(text: existingData?["organization"] ?? ""),
        "issueDate": TextEditingController(text: existingData?["issueDate"] ?? ""),
        "expirationDate": TextEditingController(text: existingData?["expirationDate"] ?? ""),
        "credentialId": TextEditingController(text: existingData?["credentialId"] ?? ""),
        "credentialUrl": TextEditingController(text: existingData?["credentialUrl"] ?? ""),
      };
      break;
    case "projects":
      controllers = {
        "name": TextEditingController(text: existingData?["name"] ?? ""),
        "startDate": TextEditingController(text: existingData?["startDate"] ?? ""),
        "endDate": TextEditingController(text: existingData?["endDate"] ?? ""),
        "description": TextEditingController(text: existingData?["description"] ?? ""),
        "projectUrl": TextEditingController(text: existingData?["projectUrl"] ?? ""),
      };
      break;
    case "volunteering":
      controllers = {
        "organization": TextEditingController(text: existingData?["organization"] ?? ""),
        "role": TextEditingController(text: existingData?["role"] ?? ""),
        "cause": TextEditingController(text: existingData?["cause"] ?? ""),
        "startDate": TextEditingController(text: existingData?["startDate"] ?? ""),
        "endDate": TextEditingController(text: existingData?["endDate"] ?? ""),
        "description": TextEditingController(text: existingData?["description"] ?? ""),
        "url": TextEditingController(text: existingData?["url"] ?? ""),
      };
      break;
    case "education":
      controllers = {
        "school": TextEditingController(text: existingData?["school"] ?? ""),
        "degree": TextEditingController(text: existingData?["degree"] ?? ""),
        "field": TextEditingController(text: existingData?["field"] ?? ""),
        "gpa": TextEditingController(text: existingData?["gpa"]?.toString() ?? ""),
        "startMonth": TextEditingController(text: existingData?["startMonth"] ?? ""),
        "startYear": TextEditingController(text: existingData?["startYear"] ?? ""),
        "endMonth": TextEditingController(text: existingData?["endMonth"] ?? ""),
        "endYear": TextEditingController(text: existingData?["endYear"] ?? ""),
        "description": TextEditingController(text: existingData?["description"] ?? ""),
        "year": TextEditingController(text: existingData?["year"]?.toString() ?? ""),
      };
      break;
    default:
      return; // unsupported type
  }

  // -------------------- Bottom Sheet --------------------
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 125, 186, 223),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${existingData == null ? "Add" : "Edit"} ${type[0].toUpperCase()}${type.substring(1)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                // Form Fields
                ...controllers.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: e.value,
                      validator: (v) => v == null || v.isEmpty
                          ? "${e.key[0].toUpperCase()}${e.key.substring(1)} is required"
                          : null,
                      decoration: InputDecoration(
                        labelText: e.key[0].toUpperCase() + e.key.substring(1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      Map<String, dynamic> newData = {};
                      controllers.forEach((k, v) => newData[k] = v.text.trim());

                      // ------------------ Update Provider ------------------
                      switch (type) {
                        case "licenses":
                          final list = List<Map<String, dynamic>>.from(provider.studentProfile["licenses"]);
                          if (index != null) {
                            list[index] = newData;
                          } else {
                            list.add(newData);
                          }
                          provider.setLicenses(list);
                          break;
                        case "projects":
                          final list = List<Map<String, dynamic>>.from(provider.studentProfile["projects"]);
                          if (index != null) {
                            list[index] = newData;
                          } else {
                            list.add(newData);
                          }
                          provider.setProjects(list);
                          break;
                        case "volunteering":
                          final list = List<Map<String, dynamic>>.from(provider.studentProfile["volunteering"]);
                          if (index != null) {
                            list[index] = newData;
                          } else {
                            list.add(newData);
                          }
                          provider.setVolunteering(list);
                          break;
                        case "education":
                          final list = List<Map<String, dynamic>>.from(provider.studentProfile["education"]);
                          if (index != null) {
                            list[index] = newData;
                          } else {
                            list.add(newData);
                          }
                          provider.setEducation(list);
                          break;
                      }

                      // ------------------ Call API ------------------
                      final success = await provider.updateProfile();
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to save data. Try again.")),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
