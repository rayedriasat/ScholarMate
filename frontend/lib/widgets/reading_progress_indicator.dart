import 'package:flutter/material.dart';

/// Reading progress indicator for PDF viewer
/// Displays a subtle progress bar at the bottom showing reading progress
class ReadingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const ReadingProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages == 0) return const SizedBox.shrink();

    final progress = currentPage / totalPages;

    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.3),
            Theme.of(context).primaryColor,
          ],
          stops: [progress, progress],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}
