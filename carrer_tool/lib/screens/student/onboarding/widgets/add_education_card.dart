import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEducationCard extends StatefulWidget {
  final TextEditingController school;
  final TextEditingController degree;
  final TextEditingController field;
  final TextEditingController gpa;
  final TextEditingController description;
  final TextEditingController year;
  final TextEditingController startMonth;
  final TextEditingController startYear;
  final TextEditingController endMonth;
  final TextEditingController endYear;
  final VoidCallback onRemove;
  final bool requireValidation;

  const AddEducationCard({
    super.key,
    required this.school,
    required this.degree,
    required this.field,
    required this.gpa,
    required this.description,
    required this.year,
    required this.startMonth,
    required this.startYear,
    required this.endMonth,
    required this.endYear,
    required this.onRemove,
    this.requireValidation = false,
  });

  @override
  State<AddEducationCard> createState() => _AddEducationCardState();
}

class _AddEducationCardState extends State<AddEducationCard>
    with TickerProviderStateMixin {
  final List<String> months = const [
    "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"
  ];

  List<String> years() {
  int currentYear = DateTime.now().year;

  // Past 50 years
  List<String> pastYears =
      List.generate(20, (index) => (currentYear - index).toString());

  // Next 4 future years
  List<String> futureYears =
      List.generate(4, (index) => (currentYear + (index + 1)).toString());

  // Combine and sort descending
  List<String> allYears = [...futureYears, ...pastYears];

  allYears.sort((a, b) => int.parse(b).compareTo(int.parse(a)));

  return allYears;
}



  bool _hovering = false;
  int _descriptionLines = 1;
  List<String> _universities = [];
  bool _loadingUniversities = false;

  @override
  void initState() {
    super.initState();
    fetchUniversities();
  }

  Future<void> fetchUniversities() async {
    setState(() => _loadingUniversities = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:4000/api/university-rankings/names'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _universities = List<String>.from(data);
        });
      } else {
        debugPrint("Failed to load universities: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching universities: $e");
    } finally {
      setState(() => _loadingUniversities = false);
    }
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
    );
  }

  Widget buildTextField(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
}) {
  final isDescription = label.toLowerCase() == "description";

  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    minLines: isDescription ? 1 : 1,
    maxLines: isDescription ? 6 : 1,   // expand smoothly until 6 lines
    onChanged: (v) {
      if (isDescription) {
        final lines = '\n'.allMatches(v).length + 1;
        setState(() => _descriptionLines = lines.clamp(1, 6));
      }
    },
    validator: (v) {
      if (!widget.requireValidation) return null;
      if (v == null || v.trim().isEmpty) {
        if (label.toLowerCase() == "gpa") return "GPA is required";
        if (label.toLowerCase() == "year") return "Year is required";
        return "$label is required";
      }
      if (label.toLowerCase() == "gpa") {
        final gpa = double.tryParse(v);
        if (gpa == null || gpa < 1 || gpa > 4) {
          return "GPA must be between 1.0 and 4.0";
        }
      }
      if (label.toLowerCase() == "year") {
        if (int.tryParse(v) == null) return "Year must be a number";
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF3B82F6),
          width: 2,
        ),
      ),
    ),
  );
}

  Widget buildUniversityDropdown() {
    if (_loadingUniversities) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }

    if (_universities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text("No universities found", style: TextStyle(color: Colors.grey)),
      );
    }

    return DropdownButtonFormField<String>(
      value: widget.school.text.isEmpty ? null : widget.school.text,
      items: _universities.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) => setState(() => widget.school.text = v ?? ""),
      validator: (v) {
        if (!widget.requireValidation) return null;
        if (v == null || v.trim().isEmpty) return "School is required";
        return null;
      },
      decoration: _dropdownDecoration("School / University"),
      dropdownColor: Colors.white, // dropdown menu white
    );
  }

  Widget buildMonthYearRangePicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<Map<String, String>>(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) {
              String tempStartMonth = widget.startMonth.text;
              String tempStartYear = widget.startYear.text;
              String tempEndMonth = widget.endMonth.text;
              String tempEndYear = widget.endYear.text;

              return StatefulBuilder(
                  builder: (context, setSheetState) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Select Duration",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: tempStartMonth.isEmpty ? null : tempStartMonth,
                                    items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                    onChanged: (v) => setSheetState(() => tempStartMonth = v!),
                                    decoration: _dropdownDecoration("Start Month"),
                                    dropdownColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: tempStartYear.isEmpty ? null : tempStartYear,
                                    items: years().map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                    onChanged: (v) => setSheetState(() => tempStartYear = v!),
                                    decoration: _dropdownDecoration("Start Year"),
                                    dropdownColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: tempEndMonth.isEmpty ? null : tempEndMonth,
                                    items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                    onChanged: (v) => setSheetState(() => tempEndMonth = v!),
                                    decoration: _dropdownDecoration("End Month"),
                                    dropdownColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: tempEndYear.isEmpty ? null : tempEndYear,
                                    items: years().map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                    onChanged: (v) => setSheetState(() => tempEndYear = v!),
                                    decoration: _dropdownDecoration("End Year"),
                                    dropdownColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop({
                                  "startMonth": tempStartMonth,
                                  "startYear": tempStartYear,
                                  "endMonth": tempEndMonth,
                                  "endYear": tempEndYear,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700, // Blue background
                                foregroundColor: Colors.white, // White text
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // Optional: rounded corners
                                ),
                              ),
                              child: const Text(
                                "Confirm",
                                style: TextStyle(fontWeight: FontWeight.bold), // Optional: bold text
                              ),
                            ),
                          ],
                        ),
                      ));
            });

        if (selected != null) {
          setState(() {
            widget.startMonth.text = selected["startMonth"]!;
            widget.startYear.text = selected["startYear"]!;
            widget.endMonth.text = selected["endMonth"]!;
            widget.endYear.text = selected["endYear"]!;
          });
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          widget.startMonth.text.isEmpty
              ? "Duration"
              : "${widget.startMonth.text} ${widget.startYear.text} - ${widget.endMonth.text} ${widget.endYear.text}",
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(_hovering ? 0.15 : 0.08),
              blurRadius: _hovering ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: const [
                    Text("Education",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                buildUniversityDropdown(),
                const SizedBox(height: 10),
                buildTextField(widget.degree, "Degree"),
                const SizedBox(height: 10),
                buildTextField(widget.field, "Field of Study"),
                const SizedBox(height: 10),
                buildMonthYearRangePicker(),
                const SizedBox(height: 10),
                buildTextField(widget.gpa, "GPA", keyboardType: TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 10),
                buildTextField(widget.description, "Description", keyboardType: TextInputType.multiline),
                const SizedBox(height: 10),
                buildTextField(widget.year, "Year", keyboardType: TextInputType.number),
              ],
            ),
            Positioned(
              right: 0,
              top: -10,
              child: IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
