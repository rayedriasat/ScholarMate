import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for text-to-speech functionality
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 0.5; // Default speed (0.0 - 1.0)
  double _pitch = 1.0;
  double _volume = 1.0;

  String _currentText = '';
  int _currentWordStart = 0;
  int _currentWordEnd = 0;

  // Callback for when speech completes
  VoidCallback? _onComplete;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  int get currentWordStart => _currentWordStart;
  int get currentWordEnd => _currentWordEnd;

  TtsService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      // Set default language
      await _flutterTts.setLanguage('en-US');

      // Set initial values
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

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
      _currentText = text;
      _onComplete = onComplete;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
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

  /// Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
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
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
