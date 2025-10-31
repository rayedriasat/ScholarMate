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
                  max: 2.0, // Extended to 200%
                  divisions: 20,
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
                      'Slow (0%)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Fast (200%)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick speed presets
                Wrap(
                  spacing: 8,
                  children: [
                    _SpeedPresetChip(
                      label: '50%',
                      value: 0.5,
                      isSelected: (ttsService.speechRate - 0.5).abs() < 0.05,
                      onTap: () {
                        ttsService.setSpeechRate(0.5);
                        setState(() {});
                      },
                    ),
                    _SpeedPresetChip(
                      label: '75%',
                      value: 0.75,
                      isSelected: (ttsService.speechRate - 0.75).abs() < 0.05,
                      onTap: () {
                        ttsService.setSpeechRate(0.75);
                        setState(() {});
                      },
                    ),
                    _SpeedPresetChip(
                      label: '100%',
                      value: 1.0,
                      isSelected: (ttsService.speechRate - 1.0).abs() < 0.05,
                      onTap: () {
                        ttsService.setSpeechRate(1.0);
                        setState(() {});
                      },
                    ),
                    _SpeedPresetChip(
                      label: '125%',
                      value: 1.25,
                      isSelected: (ttsService.speechRate - 1.25).abs() < 0.05,
                      onTap: () {
                        ttsService.setSpeechRate(1.25);
                        setState(() {});
                      },
                    ),
                    _SpeedPresetChip(
                      label: '150%',
                      value: 1.5,
                      isSelected: (ttsService.speechRate - 1.5).abs() < 0.05,
                      onTap: () {
                        ttsService.setSpeechRate(1.5);
                        setState(() {});
                      },
                    ),
                    _SpeedPresetChip(
                      label: '200%',
                      value: 2.0,
                      isSelected: (ttsService.speechRate - 2.0).abs() < 0.05,
                      onTap: () {
                        ttsService.setSpeechRate(2.0);
                        setState(() {});
                      },
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

  void _showVoiceDialog(BuildContext context, TtsService ttsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Selection'),
        content: StatefulBuilder(
          builder: (context, setState) {
            final voiceOptions = ttsService.getVoiceOptions();
            final totalVoices = ttsService.availableVoices.length;

            if (voiceOptions.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.voice_over_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text('No voices available'),
                  const SizedBox(height: 8),
                  Text(
                    'Total system voices: $totalVoices',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Reload voices
                      await ttsService.debugPrintAllVoices();
                      setState(() {});
                    },
                    child: const Text('Reload Voices'),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available voices (${voiceOptions.length} of $totalVoices)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ...voiceOptions.map((voice) {
                  final isSelected = ttsService.selectedVoice == voice['name'];

                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(voice['displayName']!),
                    subtitle: Text('${voice['locale']} • ${voice['name']}'),
                    onTap: () {
                      ttsService.setVoice(voice['name']!);
                      setState(() {});
                    },
                  );
                }),
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

              const SizedBox(width: 8),

              // Voice selection
              IconButton(
                icon: const Icon(Icons.record_voice_over),
                onPressed: () => _showVoiceDialog(context, ttsService),
                tooltip: 'Voice: ${ttsService.selectedVoice ?? 'Default'}',
                iconSize: 20,
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

/// Speed preset chip widget
class _SpeedPresetChip extends StatelessWidget {
  final String label;
  final double value;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedPresetChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
