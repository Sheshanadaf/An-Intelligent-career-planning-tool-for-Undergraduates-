import 'package:flutter/material.dart';

class AddEducationCard extends StatelessWidget {
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

  final List<String> months = const [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  List<String> years() {
    int currentYear = DateTime.now().year;
    return List.generate(50, (index) => (currentYear - index).toString());
  }

  Widget buildDropdown(String label, TextEditingController controller, List<String> options) {
    return DropdownButtonFormField<String>(
      initialValue: controller.text.isEmpty ? null : controller.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) => controller.text = val ?? "",
      validator: requireValidation ? (v) => v == null || v.isEmpty ? "Required" : null : null,
    );
  }

  Widget buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: requireValidation
          ? (v) => v == null || v.trim().isEmpty ? "$label is required" : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row with title and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Education",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),

            buildTextField(school, "School"),
            const SizedBox(height: 12),
            buildTextField(degree, "Degree"),
            const SizedBox(height: 12),
            buildTextField(field, "Field of Study"),
            const SizedBox(height: 12),

            // Start & End Month/Year Row
            Row(
              children: [
                Expanded(child: buildDropdown("Start Month", startMonth, months)),
                const SizedBox(width: 10),
                Expanded(child: buildDropdown("Start Year", startYear, years())),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: buildDropdown("End Month", endMonth, months)),
                const SizedBox(width: 10),
                Expanded(child: buildDropdown("End Year", endYear, years())),
              ],
            ),
            const SizedBox(height: 12),

            buildTextField(gpa, "GPA", keyboardType: TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            buildTextField(description, "Description", keyboardType: TextInputType.multiline, maxLines: 3),
            const SizedBox(height: 12),
            buildTextField(year, "Year", keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }
}
