import 'package:flutter/material.dart';
import '../config/theme.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController notesController;
  final VoidCallback onSave;
  final ValueChanged<String> onChanged;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final bool showSaveButton;

  const NotesSection({
    Key? key,
    required this.notesController,
    required this.onSave,
    required this.onChanged,
    this.isSaving = false,
    this.hasUnsavedChanges = false,
    this.showSaveButton = false, // Default to false for auto-save mode
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Notes', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(width: 8),
            if (isSaving)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (hasUnsavedChanges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Unsaved',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[700],
                    fontSize: 10,
                  ),
                ),
              )
            else if (!hasUnsavedChanges && notesController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Saved',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successGreen,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add your notes here... (auto-saves as you type)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: onChanged,
        ),
        if (showSaveButton) ...[
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
      ],
    );
  }
}
