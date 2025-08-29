import 'package:flutter/material.dart';
import '../config/theme.dart';

class SuggestionsSection extends StatelessWidget {
  final String? suggestions;
  const SuggestionsSection({Key? key, required this.suggestions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (suggestions == null || suggestions!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    List<String> lines = suggestions!.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length <= 1 && suggestions!.contains(' - ')) {
      lines = suggestions!
          .split(' - ')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }
    lines = lines.map((l) {
      String cleaned = l.trim();
      if (cleaned.startsWith('-')) cleaned = cleaned.substring(1).trim();
      if (cleaned.startsWith('•')) cleaned = cleaned.substring(1).trim();
      return cleaned;
    }).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Color(0xFF4EE0BD), size: 22),
                const SizedBox(width: 8),
                Text('Suggestions', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                )),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: Color(0xFF232B3A)),
            const SizedBox(height: 16),
            ...lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•', style: TextStyle(fontSize: 28, height: 1.1, color: Color(0xFF4EE0BD))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
