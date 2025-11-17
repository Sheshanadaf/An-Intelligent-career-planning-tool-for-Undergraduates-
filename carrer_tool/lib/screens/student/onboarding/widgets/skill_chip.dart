import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String text;
  final VoidCallback onDelete;
  const SkillChip({super.key, required this.text, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      onDeleted: onDelete,
    );
  }
}
