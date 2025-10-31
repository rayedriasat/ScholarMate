import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';

/// Widget for text-to-speech controls
class TtsControls extends StatelessWidget {
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onPlay;
  final bool canGoNext;
  final bool canGoPrevious;

  const TtsControls({
    super.key,
    this.onNextPage,
    this.onPreviousPage,
    this.onPlay,
    this.canGoNext = true,
    this.canGoPrevious = true,
  });

  void _showSpeedDialog(BuildContext context, TtsService ttsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speech Speed'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(ttsService.speechRate * 100).round()}%',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Slider(
                  value: ttsService.speechRate,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(ttsService.speechRate * 100).round()}%',
                  onChanged: (value) {
                    ttsService.setSpeechRate(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slow',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Fast',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsService>(
      builder: (context, ttsService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
          ),
          child: Row(
            children: [
              // Previous page button
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: canGoPrevious ? onPreviousPage : null,
                tooltip: 'Previous page',
                iconSize: 20,
              ),

              // Play/Pause button
              IconButton(
                icon: Icon(
                  ttsService.isPlaying && !ttsService.isPaused
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  if (ttsService.isPlaying && !ttsService.isPaused) {
                    ttsService.pause();
                  } else if (ttsService.isPaused) {
                    ttsService.resume();
                  } else {
                    // Start playing - call parent's onPlay
                    onPlay?.call();
                  }
                },
                tooltip: ttsService.isPlaying && !ttsService.isPaused
                    ? 'Pause'
                    : 'Play',
                color: Colors.blue[700],
                iconSize: 28,
              ),

              // Stop button
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: ttsService.isPlaying
                    ? () => ttsService.stop()
                    : null,
                tooltip: 'Stop',
                iconSize: 20,
              ),

              // Next page button
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: canGoNext ? onNextPage : null,
                tooltip: 'Next page',
                iconSize: 20,
              ),

              const SizedBox(width: 8),

              // Speed control
              IconButton(
                icon: const Icon(Icons.speed),
                onPressed: () => _showSpeedDialog(context, ttsService),
                tooltip: 'Speed: ${(ttsService.speechRate * 100).round()}%',
                iconSize: 20,
              ),

              // Speed indicator
              Text(
                '${(ttsService.speechRate * 100).round()}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),

              const Spacer(),

              // Status indicator
              if (ttsService.isPlaying)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[700]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ttsService.isPaused ? 'Paused' : 'Reading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
