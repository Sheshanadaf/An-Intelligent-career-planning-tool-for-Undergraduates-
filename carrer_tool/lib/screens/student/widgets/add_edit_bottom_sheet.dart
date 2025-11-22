import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        "credentialId": TextEditingController(text: existingData?["credentialId"] ?? ""),
        "credentialUrl": TextEditingController(text: existingData?["credentialUrl"] ?? ""),
        "startMonth": TextEditingController(text: existingData?["issueDate"]?.split(" ").first ?? ""),
        "startYear": TextEditingController(text: existingData?["issueDate"]?.split(" ").last ?? ""),
        "endMonth": TextEditingController(text: existingData?["expirationDate"]?.split(" ").first ?? ""),
        "endYear": TextEditingController(text: existingData?["expirationDate"]?.split(" ").last ?? ""),
      };
      break;
    case "projects":
      controllers = {
        "name": TextEditingController(text: existingData?["name"] ?? ""),
        "description": TextEditingController(text: existingData?["description"] ?? ""),
        "projectUrl": TextEditingController(text: existingData?["projectUrl"] ?? ""),
        "startMonth": TextEditingController(text: existingData?["startDate"]?.split(" ").first ?? ""),
        "startYear": TextEditingController(text: existingData?["startDate"]?.split(" ").last ?? ""),
        "endMonth": TextEditingController(text: existingData?["endDate"]?.split(" ").first ?? ""),
        "endYear": TextEditingController(text: existingData?["endDate"]?.split(" ").last ?? ""),
      };
      break;
    case "volunteering":
      controllers = {
        "organization": TextEditingController(text: existingData?["organization"] ?? ""),
        "role": TextEditingController(text: existingData?["role"] ?? ""),
        "cause": TextEditingController(text: existingData?["cause"] ?? ""),
        "description": TextEditingController(text: existingData?["description"] ?? ""),
        "url": TextEditingController(text: existingData?["url"] ?? ""),
        "startMonth": TextEditingController(text: existingData?["startDate"]?.split(" ").first ?? ""),
        "startYear": TextEditingController(text: existingData?["startDate"]?.split(" ").last ?? ""),
        "endMonth": TextEditingController(text: existingData?["endDate"]?.split(" ").first ?? ""),
        "endYear": TextEditingController(text: existingData?["endDate"]?.split(" ").last ?? ""),
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
      return;
  }

  // -------------------- Helpers --------------------
  List<String> months = const [
    "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"
  ];

  List<String> years() {
    int currentYear = DateTime.now().year;
    List<String> pastYears = List.generate(50, (i) => (currentYear - i).toString());
    List<String> futureYears = List.generate(4, (i) => (currentYear + i + 1).toString());
    List<String> allYears = [...futureYears, ...pastYears];
    allYears.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    return allYears;
  }

  List<String> universities = [];
  bool loadingUniversities = true;

  Future<void> fetchUniversities() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:4000/api/university-rankings/names'));
      if (response.statusCode == 200) {
        universities = List<String>.from(json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Failed fetching universities: $e");
    } finally {
      loadingUniversities = false;
    }
  }

  if (type == "education") {
    await fetchUniversities();
  }

  // Map of special display names
  final Map<String, String> typeDisplayNames = {
    "licenses": "Certification and Badges",
  };

  // -------------------- Bottom Sheet --------------------
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (context, setStateSheet) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // -------------------- Header --------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      "${existingData == null ? "Add" : "Edit"} ${typeDisplayNames[type] ?? type[0].toUpperCase() + type.substring(1)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(thickness: 1, color: Colors.black12),
                  const SizedBox(height: 16),

                  // -------------------- Form Fields --------------------
                  ...controllers.entries.map((e) {
                    // -------------------- School/University --------------------
                    if (type == "education" && e.key == "school") {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            if (loadingUniversities) return;

                            List<String> filteredUniversities = List.from(universities);
                            String searchQuery = '';

                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) => StatefulBuilder(
                                builder: (context, setSheetState) => Padding(
                                  padding: EdgeInsets.only(
                                    top: 16,
                                    left: 16,
                                    right: 16,
                                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: "Search university",
                                            prefixIcon: const Icon(Icons.search),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          onChanged: (val) {
                                            searchQuery = val.toLowerCase();
                                            setSheetState(() {
                                              filteredUniversities = universities
                                                  .where((u) => u.toLowerCase().contains(searchQuery))
                                                  .toList();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 300,
                                        child: filteredUniversities.isEmpty
                                            ? const Center(child: Text("No universities found"))
                                            : ListView.separated(
                                                itemCount: filteredUniversities.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1),
                                                itemBuilder: (context, index) {
                                                  final uni = filteredUniversities[index];
                                                  return ListTile(
                                                    title: Text(
                                                      uni,
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                    trailing: e.value.text == uni
                                                        ? const Icon(Icons.check, color: Colors.blue)
                                                        : null,
                                                    onTap: () => Navigator.pop(context, uni),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            if (selected != null) {
                              setStateSheet(() => e.value.text = selected);
                            }
                          },
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.value.text.isEmpty ? "Select School / University" : e.value.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: e.value.text.isEmpty ? Colors.grey.shade600 : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // -------------------- Description field --------------------
                    if (e.key == "description") {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 60, maxHeight: 200),
                          child: TextFormField(
                            controller: e.value,
                            maxLines: null,
                            validator: (v) => v == null || v.isEmpty ? "${e.key} is required" : null,
                            decoration: InputDecoration(
                              labelText: e.key[0].toUpperCase() + e.key.substring(1),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    Map<String, String> customLabels = {
                      "gpa": "GPA",
                      "credentialId": "Credential ID",
                      "credentialUrl": "Credential Url",
                      "projectUrl":"Project Url",
                      "url":"WebSite link",
                      "xyz": "Some Other Label",
                      // add more mappings here
                    };

                    // -------------------- Normal text fields excluding duration --------------------
                    if (!["startMonth","startYear","endMonth","endYear"].contains(e.key)) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: e.value,
                          maxLines: 1,
                          validator: (v) => v == null || v.isEmpty ? "${e.key} is required" : null,
                          decoration: InputDecoration(
                            labelText: customLabels.containsKey(e.key) 
                              ? customLabels[e.key]! 
                              : e.key[0].toUpperCase() + e.key.substring(1),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  }).toList(),

                  // -------------------- Duration Picker --------------------
                  if (["licenses","projects","volunteering","education"].contains(type)) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          String tempStartMonth = controllers["startMonth"]!.text;
                          String tempStartYear = controllers["startYear"]!.text;
                          String tempEndMonth = controllers["endMonth"]!.text;
                          String tempEndYear = controllers["endYear"]!.text;
                          bool isPresent = tempEndMonth.toLowerCase() == "present" || tempEndYear.toLowerCase() == "present";

                          final result = await showModalBottomSheet<Map<String, String>>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (ctx) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: StatefulBuilder(
                                builder: (context, setDurationState) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Select Duration",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: tempStartMonth.isEmpty ? null : tempStartMonth,
                                            items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                            onChanged: (v) => setDurationState(() => tempStartMonth = v!),
                                            decoration: InputDecoration(
                                              labelText: "Start Month",
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: tempStartYear.isEmpty ? null : tempStartYear,
                                            items: years().map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                            onChanged: (v) => setDurationState(() => tempStartYear = v!),
                                            decoration: InputDecoration(
                                              labelText: "Start Year",
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    CheckboxListTile(
                                      title: const Text("Present"),
                                      value: isPresent,
                                      onChanged: (val) => setDurationState(() {
                                        isPresent = val ?? false;
                                        if (isPresent) {
                                          tempEndMonth = "Present";
                                          tempEndYear = "";
                                        }
                                      }),
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: isPresent ? null : (tempEndMonth.isEmpty ? null : tempEndMonth),
                                            items: [...months.map((m) => DropdownMenuItem(value: m, child: Text(m))), const DropdownMenuItem(value: "Present", child: Text("Present"))],
                                            onChanged: isPresent ? null : (v) => setDurationState(() => tempEndMonth = v!),
                                            decoration: InputDecoration(
                                              labelText: "End Month",
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: isPresent ? null : (tempEndYear.isEmpty ? null : tempEndYear),
                                            items: years().map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                            onChanged: isPresent ? null : (v) => setDurationState(() => tempEndYear = v!),
                                            decoration: InputDecoration(
                                              labelText: "End Year",
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx, {
                                          "startMonth": tempStartMonth,
                                          "startYear": tempStartYear,
                                          "endMonth": isPresent ? "Present" : tempEndMonth,
                                          "endYear": isPresent ? "" : tempEndYear,
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text("Confirm", style: TextStyle(fontSize: 16)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (result != null) {
                            setStateSheet(() {
                              controllers["startMonth"]!.text = result["startMonth"]!;
                              controllers["startYear"]!.text = result["startYear"]!;
                              controllers["endMonth"]!.text = result["endMonth"]!;
                              controllers["endYear"]!.text = result["endYear"]!;
                            });
                          }
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controllers["startMonth"]!.text.isEmpty
                                    ? "Select Duration"
                                    : "${controllers["startMonth"]!.text} ${controllers["startYear"]!.text} - ${controllers["endMonth"]!.text} ${controllers["endYear"]!.text}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: controllers["startMonth"]!.text.isEmpty ? Colors.grey.shade600 : Colors.black87,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  // -------------------- Save Button --------------------
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        Map<String, dynamic> newData = {};
                        controllers.forEach((k, v) => newData[k] = v.text.trim());

                        if (type == "licenses") {
                          newData["issueDate"] = "${controllers["startMonth"]!.text} ${controllers["startYear"]!.text}";
                          newData["expirationDate"] = "${controllers["endMonth"]!.text} ${controllers["endYear"]!.text}";
                        } else if (type == "projects") {
                          newData["startDate"] = "${controllers["startMonth"]!.text} ${controllers["startYear"]!.text}";
                          newData["endDate"] = "${controllers["endMonth"]!.text} ${controllers["endYear"]!.text}";
                        } else if (type == "volunteering") {
                          newData["startDate"] = "${controllers["startMonth"]!.text} ${controllers["startYear"]!.text}";
                          newData["endDate"] = "${controllers["endMonth"]!.text} ${controllers["endYear"]!.text}";
                        }

                        switch (type) {
                          case "licenses":
                            final list = List<Map<String, dynamic>>.from(provider.studentProfile["licenses"]);
                            if (index != null) list[index] = newData; else list.add(newData);
                            provider.setLicenses(list);
                            break;
                          case "projects":
                            final list = List<Map<String, dynamic>>.from(provider.studentProfile["projects"]);
                            if (index != null) list[index] = newData; else list.add(newData);
                            provider.setProjects(list);
                            break;
                          case "volunteering":
                            final list = List<Map<String, dynamic>>.from(provider.studentProfile["volunteering"]);
                            if (index != null) list[index] = newData; else list.add(newData);
                            provider.setVolunteering(list);
                            break;
                          case "education":
                            final list = List<Map<String, dynamic>>.from(provider.studentProfile["education"]);
                            if (index != null) list[index] = newData; else list.add(newData);
                            provider.setEducation(list);
                            break;
                        }

                        final success = await provider.updateProfile();
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to save data. Try again.")));
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "Save",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
