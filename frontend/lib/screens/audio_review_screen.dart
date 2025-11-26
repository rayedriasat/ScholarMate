import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioReviewScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> segments;

  const AudioReviewScreen({
    super.key,
    required this.title,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AudioReviewView(
        title: title,
        segments: segments,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

class AudioReviewView extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> segments;
  final VoidCallback? onClose;

  const AudioReviewView({
    super.key,
    required this.title,
    required this.segments,
    this.onClose,
  });

  @override
  State<AudioReviewView> createState() => _AudioReviewViewState();
}

class _AudioReviewViewState extends State<AudioReviewView> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  int _currentSegmentIndex = 0;
  double _speechRate = 1.0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (_currentSegmentIndex < widget.segments.length - 1) {
        setState(() {
          _currentSegmentIndex++;
        });
        _speakCurrentSegment();
      } else {
        setState(() {
          _isPlaying = false;
          _currentSegmentIndex = 0;
        });
      }
    });
  }

  Future<void> _speakCurrentSegment() async {
    if (_currentSegmentIndex >= widget.segments.length) return;

    final segment = widget.segments[_currentSegmentIndex];
    final speaker = segment['speaker'] ?? 'Host 1';
    final text = segment['text'] ?? '';

    // Adjust voice based on speaker
    if (speaker.contains('1') || speaker.toLowerCase().contains('alex')) {
      await _tts.setPitch(1.0); // Normal pitch for Host 1
    } else {
      await _tts.setPitch(0.9); // Slightly lower pitch for Host 2
    }

    await _tts.speak(text);
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _tts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _speakCurrentSegment();
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() {
      _isPlaying = false;
      _currentSegmentIndex = 0;
    });
  }

  Future<void> _changeSpeechRate(double rate) async {
    setState(() {
      _speechRate = rate;
    });
    await _tts.setSpeechRate(rate);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Close button if embedded
        if (widget.onClose != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Podcast-style banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.headphones,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio Review',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.segments.length} segments',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Playback controls
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: _isPlaying ? _stop : null,
                iconSize: 32,
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: _togglePlayback,
                iconSize: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 24),
              // Speed control
              PopupMenuButton<double>(
                icon: Row(
                  children: [
                    Text(
                      '${_speechRate}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onSelected: _changeSpeechRate,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                  const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                  const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Transcript
        Expanded(
          child: ListView.builder(
            itemCount: widget.segments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final segment = widget.segments[index];
              final speaker = segment['speaker'] ?? 'Host';
              final text = segment['text'] ?? '';
              final isActive = index == _currentSegmentIndex && _isPlaying;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color:
                              speaker.contains('1') ||
                                  speaker.toLowerCase().contains('alex')
                              ? Colors.blue
                              : Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          speaker,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.volume_up,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isActive ? Colors.black : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
