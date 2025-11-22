import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/platform_detector.dart';

void main() {
  group('PlatformDetector', () {
    test('detectPlatform returns a valid platform', () {
      final platform = PlatformDetector.detectPlatform();
      expect(platform, isA<AIPlatform>());
      expect(platform, isNot(equals(AIPlatform.unsupported)));
    });

    test('isNativePlatform and isWebPlatform are mutually exclusive', () {
      final isNative = PlatformDetector.isNativePlatform();
      final isWeb = PlatformDetector.isWebPlatform();

      // One must be true, but not both
      expect(isNative || isWeb, isTrue);
      expect(isNative && isWeb, isFalse);
    });

    test('supportsOnnxRuntime returns true for native platforms', () {
      final isNative = PlatformDetector.isNativePlatform();
      final supportsOnnx = PlatformDetector.supportsOnnxRuntime();

      if (isNative) {
        expect(supportsOnnx, isTrue);
      }
    });

    test('supportsLlamaCpp returns true for native platforms', () {
      final isNative = PlatformDetector.isNativePlatform();
      final supportsLlama = PlatformDetector.supportsLlamaCpp();

      if (isNative) {
        expect(supportsLlama, isTrue);
      }
    });

    test('supportsTransformersJs returns true only for web', () {
      final isWeb = PlatformDetector.isWebPlatform();
      final supportsTransformers = PlatformDetector.supportsTransformersJs();

      expect(supportsTransformers, equals(isWeb));
    });

    test('supportsWebLLM returns true only for web', () {
      final isWeb = PlatformDetector.isWebPlatform();
      final supportsWebLLM = PlatformDetector.supportsWebLLM();

      expect(supportsWebLLM, equals(isWeb));
    });

    test('getRecommendedEmbeddingBackend returns appropriate backend', () {
      final backend = PlatformDetector.getRecommendedEmbeddingBackend();

      if (PlatformDetector.isWebPlatform()) {
        expect(backend, equals('Transformers.js'));
      } else if (PlatformDetector.isNativePlatform()) {
        expect(backend, equals('ONNX Runtime'));
      }
    });

    test('getRecommendedLLMBackend returns appropriate backend', () {
      final backend = PlatformDetector.getRecommendedLLMBackend();

      if (PlatformDetector.isWebPlatform()) {
        expect(backend, equals('WebLLM'));
      } else if (PlatformDetector.isNativePlatform()) {
        expect(backend, equals('llama.cpp'));
      }
    });

    test('getPlatformName returns a non-empty string', () {
      final name = PlatformDetector.getPlatformName();
      expect(name, isNotEmpty);
      expect(name, isNot(equals('Unsupported')));
    });
  });
}
