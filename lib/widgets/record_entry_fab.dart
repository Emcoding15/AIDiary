import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/record_screen.dart';
import '../models/journal_entry.dart';
import '../utils/snackbar_utils.dart';

class RecordEntryFAB extends StatelessWidget {
  final BuildContext parentContext;
  final Function(JournalEntry)? onEntryAdded;
  final Function()? onEntryDeleted;

  const RecordEntryFAB({
    Key? key,
    required this.parentContext,
    this.onEntryAdded,
    this.onEntryDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.lightShadow,
        borderRadius: BorderRadius.circular(32),
      ),
      child: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () async {
          final result = await Navigator.push(
            parentContext,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RecordScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: AppTheme.mediumAnimationDuration,
            ),
          );
          if (result != null && result is JournalEntry) {
            if (onEntryAdded != null) onEntryAdded!(result);
            if (parentContext.mounted) {
              SnackBarUtils.showEntrySaved(parentContext);
            }
          } else if (result == true) {
            if (onEntryDeleted != null) onEntryDeleted!();
            if (parentContext.mounted) {
              SnackBarUtils.showEntryDeleted(parentContext);
            }
          }
        },
        elevation: 0,
        child: const Icon(
          Icons.mic_rounded,
          color: Color(0xFF1A2B2E),
          size: 24,
        ),
      ),
    );
  }
}
