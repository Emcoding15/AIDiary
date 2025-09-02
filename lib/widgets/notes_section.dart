import 'package:flutter/material.dart';
import '../config/theme.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController notesController;
  final VoidCallback onSave;
  final ValueChanged<String> onChanged;
  final bool isSaving;

  const NotesSection({
    Key? key,
    required this.notesController,
    required this.onSave,
    required this.onChanged,
    this.isSaving = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add your notes here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: isSaving
              ? const Text('Saving...')
              : const Text('Save Notes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          onPressed: isSaving ? null : onSave,
        ),
      ],
    );
  }
}
