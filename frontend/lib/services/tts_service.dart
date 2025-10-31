import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for text-to-speech functionality
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate =
      0.5; // Default speed (0.0 - 2.0, where 1.0 = 100%, 2.0 = 200%)
  double _pitch = 1.0;
  double _volume = 1.0;

  String _currentText = '';
  int _currentWordStart = 0;
  int _currentWordEnd = 0;

  // Voice selection
  List<Map<String, String>> _availableVoices = [];
  String? _selectedVoice;

  // Callback for when speech completes
  VoidCallback? _onComplete;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  int get currentWordStart => _currentWordStart;
  int get currentWordEnd => _currentWordEnd;
  List<Map<String, String>> get availableVoices => _availableVoices;
  String? get selectedVoice => _selectedVoice;

  TtsService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      // Set default language
      await _flutterTts.setLanguage('en-US');

      // Debug: Print all available voices
      await debugPrintAllVoices();

      // Get available voices
      await _loadAvailableVoices();

      // Set initial values for better quality
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

      // Enable better quality settings if available
      try {
        // Set shared instance for iOS to improve quality
        await _flutterTts.setSharedInstance(true);

        // Platform-specific quality improvements
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // iOS-specific audio quality settings
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.allowAirPlay,
            ],
            IosTextToSpeechAudioMode.spokenAudio,
          );
        }
      } catch (e) {
        // These settings might not be available on all platforms
        debugPrint('Advanced TTS settings not available: $e');
      }

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        _isPaused = false;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _isPaused = false;
        _currentWordStart = 0;
        _currentWordEnd = 0;
        notifyListeners();
        // Call completion callback if set
        _onComplete?.call();
        _onComplete = null;
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        _isPaused = false;
        _currentWordStart = 0;
        _currentWordEnd = 0;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isPlaying = false;
        _isPaused = false;
        notifyListeners();
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        notifyListeners();
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        notifyListeners();
      });

      // Progress handler for word highlighting
      _flutterTts.setProgressHandler((text, start, end, word) {
        _currentWordStart = start;
        _currentWordEnd = end;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Speak the given text
  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (text.isEmpty) return;

    try {
      // Preprocess text for more natural speech
      final processedText = _preprocessTextForSpeech(text);

      // Try to use SSML for better control if supported
      final ssmlText = _addSSMLForNaturalSpeech(processedText);

      _currentText = ssmlText;
      _onComplete = onComplete;

      // Try SSML first, fallback to plain text if not supported
      try {
        await _flutterTts.speak(ssmlText);
      } catch (e) {
        debugPrint('SSML not supported, using plain text: $e');
        await _flutterTts.speak(processedText);
      }
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  /// Add SSML markup for more natural speech patterns
  String _addSSMLForNaturalSpeech(String text) {
    // For platforms that don't support SSML well, use enhanced plain text
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _enhanceTextForNaturalPauses(text);
    }

    String ssml = text;

    // Add natural pauses with SSML
    // Long pause after sentence endings
    ssml = ssml.replaceAll(RegExp(r'([.!?])\s*'), r'$1<break time="600ms"/> ');

    // Medium pause after semicolons and colons
    ssml = ssml.replaceAll(RegExp(r'([;:])\s*'), r'$1<break time="400ms"/> ');

    // Short pause after commas
    ssml = ssml.replaceAll(RegExp(r',\s*'), r',<break time="250ms"/> ');

    // Very short pause after other punctuation
    ssml = ssml.replaceAll(RegExp(r'([—–-])\s*'), r'$1<break time="150ms"/> ');

    // Wrap in SSML speak tag
    ssml = '<speak>$ssml</speak>';

    debugPrint(
      'Generated SSML: ${ssml.length > 200 ? ssml.substring(0, 200) + "..." : ssml}',
    );

    return ssml;
  }

  /// Enhance text with natural pauses for platforms without SSML support
  String _enhanceTextForNaturalPauses(String text) {
    String enhanced = text;

    // Add extra spaces after punctuation to encourage natural pauses
    // The TTS engine will interpret multiple spaces as slight pauses

    // Sentence endings - add double space for longer pause
    enhanced = enhanced.replaceAll(RegExp(r'([.!?])\s*'), r'$1  ');

    // Semicolons and colons - add space and a half for medium pause
    enhanced = enhanced.replaceAll(RegExp(r'([;:])\s*'), r'$1 ');

    // Commas - ensure single space for short pause
    enhanced = enhanced.replaceAll(RegExp(r',\s*'), r', ');

    // Clean up any excessive spacing
    enhanced = enhanced.replaceAll(RegExp(r'  +'), '  '); // Max 2 spaces
    enhanced = enhanced.trim();

    debugPrint(
      'Enhanced text for pauses: ${enhanced.length > 200 ? enhanced.substring(0, 200) + "..." : enhanced}',
    );

    return enhanced;
  }

  /// Preprocess text to make speech sound more natural - NUCLEAR PUNCTUATION REMOVAL
  String _preprocessTextForSpeech(String text) {
    debugPrint('=== NUCLEAR PUNCTUATION REMOVAL ===');
    debugPrint('ORIGINAL: "$text"');

    String processed = text.trim();

    // Step 1: Handle abbreviations FIRST
    processed = processed.replaceAll('Dr.', 'Doctor');
    processed = processed.replaceAll('Mr.', 'Mister');
    processed = processed.replaceAll('Mrs.', 'Missus');
    processed = processed.replaceAll('Ms.', 'Miss');
    processed = processed.replaceAll('etc.', 'etcetera');

    // Step 2: Handle numbers
    processed = processed.replaceAll(RegExp(r'(\d+)\.(\d+)'), r'$1 point $2');
    processed = processed.replaceAll(RegExp(r'\$(\d+)'), r'$1 dollars');
    processed = processed.replaceAll(RegExp(r'(\d+)%'), r'$1 percent');

    // Step 3: NUCLEAR OPTION - Remove ALL punctuation
    processed = processed.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Step 4: Clean up spaces
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    processed = processed.trim();

    debugPrint('PROCESSED: "$processed"');
    return processed;
  }

  /// Pause speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  /// Resume speech
  Future<void> resume() async {
    try {
      // On some platforms, we need to continue from where we paused
      if (_isPaused) {
        // Try to use platform-specific resume if available
        await _flutterTts.speak(_currentText);
      }
    } catch (e) {
      debugPrint('Error resuming: $e');
    }
  }

  /// Stop speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _currentText = '';
      _currentWordStart = 0;
      _currentWordEnd = 0;
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  /// Set speech rate (0.0 - 2.0, where 1.0 = 100%, 2.0 = 200%)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 2.0);
      await _flutterTts.setSpeechRate(_speechRate);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  /// Set pitch (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      // Reload voices for the new language
      await _loadAvailableVoices();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  /// Load available voices
  Future<void> _loadAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        _availableVoices = List<Map<String, String>>.from(voices);

        debugPrint('Total voices found: ${_availableVoices.length}');
        for (final voice in _availableVoices) {
          debugPrint('Voice: ${voice['name']} - ${voice['locale']}');
        }

        // Filter for English voices but be more inclusive
        final englishVoices = _availableVoices.where((voice) {
          final locale = voice['locale']?.toLowerCase() ?? '';
          final name = voice['name']?.toLowerCase() ?? '';
          return locale.startsWith('en-') ||
              locale.contains('english') ||
              name.contains('english') ||
              locale == 'en' ||
              // Include common system voices even without explicit locale
              name.contains('zira') ||
              name.contains('david') ||
              name.contains('hazel') ||
              name.contains('alex') ||
              name.contains('samantha') ||
              name.contains('victoria');
        }).toList();

        debugPrint('English voices found: ${englishVoices.length}');

        if (englishVoices.isNotEmpty) {
          _availableVoices = englishVoices;
        } else {
          // If no English voices found, use all available voices
          debugPrint('No English voices found, using all available voices');
        }

        // Set default voice to a high-quality one if available
        // Prefer neural/enhanced voices for better quality
        final preferredVoices = [
          'Neural2-A',
          'Neural2-C',
          'Neural2-D',
          'Wavenet-A',
          'Wavenet-C',
          'Wavenet-D',
          'Zira',
          'David',
          'Hazel',
          'Alex',
          'Samantha',
          'Victoria',
        ];

        for (final preferred in preferredVoices) {
          final voice = _availableVoices.firstWhere(
            (v) =>
                v['name']?.toLowerCase().contains(preferred.toLowerCase()) ==
                true,
            orElse: () => {},
          );
          if (voice.isNotEmpty) {
            _selectedVoice = voice['name'];
            await _flutterTts.setVoice(voice);
            debugPrint('Selected default voice: ${voice['name']}');
            break;
          }
        }

        // If no preferred voice found, use the first available
        if (_selectedVoice == null && _availableVoices.isNotEmpty) {
          _selectedVoice = _availableVoices.first['name'];
          await _flutterTts.setVoice(_availableVoices.first);
          debugPrint(
            'Using first available voice: ${_availableVoices.first['name']}',
          );
        }

        // Enhance voice quality after setting the voice
        await enhanceVoiceQuality();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voices: $e');
    }
  }

  /// Set voice by name
  Future<void> setVoice(String voiceName) async {
    try {
      final voice = _availableVoices.firstWhere(
        (v) => v['name'] == voiceName,
        orElse: () => {},
      );

      if (voice.isNotEmpty) {
        await _flutterTts.setVoice(voice);
        _selectedVoice = voiceName;

        // Apply quality enhancements for the new voice
        await enhanceVoiceQuality();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  /// Enhance voice quality by adjusting parameters for more natural speech
  Future<void> enhanceVoiceQuality() async {
    try {
      // Optimize pitch for more natural sound and better punctuation handling
      await setPitch(0.92);

      // Optimize speech rate for natural flow with proper punctuation pauses
      // Slower rate allows punctuation pauses to be more noticeable
      if (_speechRate <= 0.6) {
        await setSpeechRate(0.65);
      }

      // Set volume to optimal level
      await setVolume(0.90);

      // Platform-specific enhancements for better punctuation handling
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Android-specific settings for better punctuation handling
          await _flutterTts.setSilence(
            0,
          ); // No artificial silence between words
          // Let natural punctuation pauses handle the timing
        }

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // iOS-specific settings for better punctuation handling
          await _flutterTts.setSharedInstance(true);

          // Enhanced audio session for better punctuation interpretation
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            ],
            IosTextToSpeechAudioMode.spokenAudio,
          );
        }

        // Enable completion awaiting for better control
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (e) {
        debugPrint('Platform-specific TTS settings not available: $e');
      }

      debugPrint(
        'Voice quality enhanced for punctuation: pitch=$_pitch, rate=$_speechRate, volume=$_volume',
      );
    } catch (e) {
      debugPrint('Error enhancing voice quality: $e');
    }
  }

  /// Get formatted voice options for UI
  List<Map<String, String>> getVoiceOptions() {
    if (_availableVoices.isEmpty) return [];

    debugPrint(
      'Getting voice options from ${_availableVoices.length} available voices',
    );

    // Return up to 3 diverse voices with better names
    final voiceOptions = <Map<String, String>>[];

    // Try to find diverse voice types with case-insensitive matching
    final voiceTypes = [
      {'pattern': 'neural', 'displayName': 'Natural Voice (Neural)'},
      {'pattern': 'wavenet', 'displayName': 'Enhanced Voice (Wavenet)'},
      {'pattern': 'zira', 'displayName': 'Clear Voice (Zira)'},
      {'pattern': 'david', 'displayName': 'Deep Voice (David)'},
      {'pattern': 'hazel', 'displayName': 'British Voice (Hazel)'},
      {'pattern': 'alex', 'displayName': 'Smooth Voice (Alex)'},
      {'pattern': 'samantha', 'displayName': 'Warm Voice (Samantha)'},
      {'pattern': 'victoria', 'displayName': 'Professional Voice (Victoria)'},
    ];

    // First pass: Look for specific voice types
    for (final type in voiceTypes) {
      if (voiceOptions.length >= 3) break;

      final voice = _availableVoices.firstWhere(
        (v) => v['name']?.toLowerCase().contains(type['pattern']!) == true,
        orElse: () => {},
      );

      if (voice.isNotEmpty &&
          !voiceOptions.any((vo) => vo['name'] == voice['name'])) {
        voiceOptions.add({
          'name': voice['name']!,
          'displayName': type['displayName']!,
          'locale': voice['locale'] ?? 'en-US',
        });
        debugPrint(
          'Added voice option: ${voice['name']} as ${type['displayName']}',
        );
      }
    }

    // Second pass: Add any remaining voices up to 3 total
    for (final voice in _availableVoices) {
      if (voiceOptions.length >= 3) break;

      if (!voiceOptions.any((vo) => vo['name'] == voice['name'])) {
        // Create a friendly display name from the voice name
        String displayName = voice['name']!;
        if (displayName.length > 20) {
          // Shorten long voice names
          final parts = displayName.split(' ');
          displayName = parts.take(2).join(' ');
        }

        voiceOptions.add({
          'name': voice['name']!,
          'displayName': displayName,
          'locale': voice['locale'] ?? 'en-US',
        });
        debugPrint(
          'Added additional voice option: ${voice['name']} as $displayName',
        );
      }
    }

    debugPrint('Final voice options count: ${voiceOptions.length}');
    return voiceOptions;
  }

  /// Debug method to print all available voices
  Future<void> debugPrintAllVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        debugPrint('=== ALL AVAILABLE VOICES ===');
        for (int i = 0; i < voices.length; i++) {
          final voice = voices[i];
          debugPrint('Voice $i: ${voice['name']} (${voice['locale']})');
        }
        debugPrint('=== END VOICES LIST ===');
      } else {
        debugPrint('No voices available or getVoices returned null');
      }
    } catch (e) {
      debugPrint('Error getting voices for debug: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
