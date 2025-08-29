import 'package:flutter/material.dart';
import '../config/theme.dart';

class SummarySection extends StatelessWidget {
  final String? summary;
  final bool isGeneratingSummary;
  final bool hasTranscription;
  final VoidCallback? onGenerateSummary;

  const SummarySection({
    Key? key,
    required this.summary,
    required this.isGeneratingSummary,
    required this.hasTranscription,
    this.onGenerateSummary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  Icons.summarize_rounded,
                  color: Color(0xFF4EE0BD),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (hasTranscription && (summary == null || summary!.isEmpty))
                  ElevatedButton.icon(
                    onPressed: isGeneratingSummary ? null : onGenerateSummary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    icon: isGeneratingSummary
                        ? Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(isGeneratingSummary ? 'Processing...' : 'Generate'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 2, color: Color(0xFF232B3A)),
            const SizedBox(height: 16),
            if (summary != null && summary!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  summary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              )
            else if (isGeneratingSummary)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating summary...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a minute',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    hasTranscription
                        ? 'Generate a summary from the transcription'
                        : 'Transcription required for summary generation',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
