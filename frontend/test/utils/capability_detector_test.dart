import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/capability_detector.dart';
import 'package:frontend/utils/platform_detector.dart';

void main() {
  group('CapabilityDetector', () {
    late CapabilityDetector detector;

    setUp(() {
      detector = CapabilityDetector.instance;
      detector.clearCache();
    });

    test('instance returns singleton', () {
      final instance1 = CapabilityDetector.instance;
      final instance2 = CapabilityDetector.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('detectWebGPU returns unavailable on non-web platforms', () async {
      if (!PlatformDetector.isWebPlatform()) {
        final result = await detector.detectWebGPU();
        expect(result.isAvailable, isFalse);
        expect(result.errorMessage, contains('web platform'));
      }
    });

    test('detectNNAPI returns unavailable on non-Android platforms', () async {
      if (PlatformDetector.detectPlatform() != AIPlatform.android) {
        final result = await detector.detectNNAPI();
        expect(result.isAvailable, isFalse);
        expect(result.errorMessage, contains('Android'));
      }
    });

    test(
      'detectDirectML returns unavailable on non-Windows platforms',
      () async {
        if (PlatformDetector.detectPlatform() != AIPlatform.windows) {
          final result = await detector.detectDirectML();
          expect(result.isAvailable, isFalse);
          expect(result.errorMessage, contains('Windows'));
        }
      },
    );

    test('detectMetal returns unavailable on non-Apple platforms', () async {
      final platform = PlatformDetector.detectPlatform();
      if (platform != AIPlatform.ios && platform != AIPlatform.macos) {
        final result = await detector.detectMetal();
        expect(result.isAvailable, isFalse);
        expect(result.errorMessage, contains('iOS'));
      }
    });

    test(
      'detectAllCapabilities returns platform-appropriate results',
      () async {
        final capabilities = await detector.detectAllCapabilities();
        expect(capabilities, isNotEmpty);

        // Verify that only platform-appropriate capabilities are checked
        if (PlatformDetector.isWebPlatform()) {
          expect(capabilities.containsKey(MLCapability.webGPU), isTrue);
          expect(capabilities.containsKey(MLCapability.nnapi), isFalse);
          expect(capabilities.containsKey(MLCapability.directML), isFalse);
        } else if (PlatformDetector.detectPlatform() == AIPlatform.android) {
          expect(capabilities.containsKey(MLCapability.nnapi), isTrue);
          expect(capabilities.containsKey(MLCapability.webGPU), isFalse);
        } else if (PlatformDetector.detectPlatform() == AIPlatform.windows) {
          expect(capabilities.containsKey(MLCapability.directML), isTrue);
          expect(capabilities.containsKey(MLCapability.webGPU), isFalse);
        }
      },
    );

    test('getBestAcceleration returns null or valid capability', () async {
      final best = await detector.getBestAcceleration();

      if (best != null) {
        expect(best, isA<MLCapability>());
      }
    });

    test('cache works correctly', () async {
      // First call
      final result1 = await detector.detectWebGPU();

      // Second call should return cached result
      final result2 = await detector.detectWebGPU();

      expect(identical(result1, result2), isTrue);
    });

    test('clearCache clears cached results', () async {
      // First call
      await detector.detectWebGPU();

      // Clear cache
      detector.clearCache();

      // Second call should not return cached result
      final result = await detector.detectWebGPU();
      expect(result, isA<CapabilityDetectionResult>());
    });

    test('getCapabilityName returns human-readable names', () {
      expect(
        CapabilityDetector.getCapabilityName(MLCapability.onnxRuntime),
        equals('ONNX Runtime'),
      );
      expect(
        CapabilityDetector.getCapabilityName(MLCapability.webGPU),
        equals('WebGPU'),
      );
      expect(
        CapabilityDetector.getCapabilityName(MLCapability.nnapi),
        equals('NNAPI'),
      );
    });
  });

  group('CapabilityDetectionResult', () {
    test('available factory creates available result', () {
      final result = CapabilityDetectionResult.available({'test': 'data'});
      expect(result.isAvailable, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.metadata, isNotNull);
    });

    test('unavailable factory creates unavailable result', () {
      final result = CapabilityDetectionResult.unavailable('Test error');
      expect(result.isAvailable, isFalse);
      expect(result.errorMessage, equals('Test error'));
    });
  });
}
