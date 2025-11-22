import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_detector.dart';

/// Result of capability detection
class CapabilityDetectionResult {
  final bool isAvailable;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const CapabilityDetectionResult({
    required this.isAvailable,
    this.errorMessage,
    this.metadata,
  });

  factory CapabilityDetectionResult.available([
    Map<String, dynamic>? metadata,
  ]) {
    return CapabilityDetectionResult(isAvailable: true, metadata: metadata);
  }

  factory CapabilityDetectionResult.unavailable(String errorMessage) {
    return CapabilityDetectionResult(
      isAvailable: false,
      errorMessage: errorMessage,
    );
  }
}

/// Hardware acceleration capability detector
class CapabilityDetector {
  static CapabilityDetector? _instance;

  // Cache detection results to avoid repeated checks
  final Map<MLCapability, CapabilityDetectionResult> _cache = {};

  CapabilityDetector._();

  static CapabilityDetector get instance {
    _instance ??= CapabilityDetector._();
    return _instance!;
  }

  /// Detects if WebGPU is available (Web platform only)
  Future<CapabilityDetectionResult> detectWebGPU() async {
    if (_cache.containsKey(MLCapability.webGPU)) {
      return _cache[MLCapability.webGPU]!;
    }

    if (!kIsWeb) {
      final result = CapabilityDetectionResult.unavailable(
        'WebGPU is only available on web platform',
      );
      _cache[MLCapability.webGPU] = result;
      return result;
    }

    // On web, we need to check if navigator.gpu is available
    // This will be implemented via JS interop in the actual web implementation
    // For now, we'll return a placeholder that assumes WebGPU might be available
    try {
      // TODO: Implement actual WebGPU detection via JS interop
      // For now, assume it's available on modern browsers
      final result = CapabilityDetectionResult.available({
        'note': 'WebGPU detection requires JS interop implementation',
      });
      _cache[MLCapability.webGPU] = result;
      return result;
    } catch (e) {
      final result = CapabilityDetectionResult.unavailable(
        'WebGPU detection failed: $e',
      );
      _cache[MLCapability.webGPU] = result;
      return result;
    }
  }

  /// Detects if NNAPI is available (Android only)
  Future<CapabilityDetectionResult> detectNNAPI() async {
    if (_cache.containsKey(MLCapability.nnapi)) {
      return _cache[MLCapability.nnapi]!;
    }

    final platform = PlatformDetector.detectPlatform();
    if (platform != AIPlatform.android) {
      final result = CapabilityDetectionResult.unavailable(
        'NNAPI is only available on Android',
      );
      _cache[MLCapability.nnapi] = result;
      return result;
    }

    // On Android, NNAPI is available on API level 27+ (Android 8.1+)
    // The actual detection will be done by ONNX Runtime when initializing
    // For now, we assume it's available on Android
    try {
      final result = CapabilityDetectionResult.available({
        'note': 'NNAPI availability will be confirmed by ONNX Runtime',
        'minApiLevel': 27,
      });
      _cache[MLCapability.nnapi] = result;
      return result;
    } catch (e) {
      final result = CapabilityDetectionResult.unavailable(
        'NNAPI detection failed: $e',
      );
      _cache[MLCapability.nnapi] = result;
      return result;
    }
  }

  /// Detects if DirectML is available (Windows only)
  Future<CapabilityDetectionResult> detectDirectML() async {
    if (_cache.containsKey(MLCapability.directML)) {
      return _cache[MLCapability.directML]!;
    }

    final platform = PlatformDetector.detectPlatform();
    if (platform != AIPlatform.windows) {
      final result = CapabilityDetectionResult.unavailable(
        'DirectML is only available on Windows',
      );
      _cache[MLCapability.directML] = result;
      return result;
    }

    // On Windows, DirectML is available on Windows 10 version 1903+
    // The actual detection will be done by ONNX Runtime when initializing
    // For now, we assume it's available on Windows
    try {
      final result = CapabilityDetectionResult.available({
        'note': 'DirectML availability will be confirmed by ONNX Runtime',
        'minWindowsVersion': '10.0.18362',
      });
      _cache[MLCapability.directML] = result;
      return result;
    } catch (e) {
      final result = CapabilityDetectionResult.unavailable(
        'DirectML detection failed: $e',
      );
      _cache[MLCapability.directML] = result;
      return result;
    }
  }

  /// Detects if Metal is available (iOS/macOS only)
  Future<CapabilityDetectionResult> detectMetal() async {
    if (_cache.containsKey(MLCapability.metal)) {
      return _cache[MLCapability.metal]!;
    }

    final platform = PlatformDetector.detectPlatform();
    if (platform != AIPlatform.ios && platform != AIPlatform.macos) {
      final result = CapabilityDetectionResult.unavailable(
        'Metal is only available on iOS and macOS',
      );
      _cache[MLCapability.metal] = result;
      return result;
    }

    // Metal is available on all modern iOS and macOS devices
    // The actual detection will be done by llama.cpp when initializing
    try {
      final result = CapabilityDetectionResult.available({
        'note': 'Metal availability will be confirmed by llama.cpp',
      });
      _cache[MLCapability.metal] = result;
      return result;
    } catch (e) {
      final result = CapabilityDetectionResult.unavailable(
        'Metal detection failed: $e',
      );
      _cache[MLCapability.metal] = result;
      return result;
    }
  }

  /// Detects if CUDA is available (Windows/Linux with NVIDIA GPU)
  Future<CapabilityDetectionResult> detectCUDA() async {
    if (_cache.containsKey(MLCapability.cuda)) {
      return _cache[MLCapability.cuda]!;
    }

    final platform = PlatformDetector.detectPlatform();
    if (platform != AIPlatform.windows && platform != AIPlatform.linux) {
      final result = CapabilityDetectionResult.unavailable(
        'CUDA is only available on Windows and Linux',
      );
      _cache[MLCapability.cuda] = result;
      return result;
    }

    // CUDA detection requires checking for NVIDIA GPU and CUDA runtime
    // This is complex and will be handled by llama.cpp
    // For now, we return unavailable by default
    try {
      final result = CapabilityDetectionResult.unavailable(
        'CUDA detection requires runtime check by llama.cpp',
      );
      _cache[MLCapability.cuda] = result;
      return result;
    } catch (e) {
      final result = CapabilityDetectionResult.unavailable(
        'CUDA detection failed: $e',
      );
      _cache[MLCapability.cuda] = result;
      return result;
    }
  }

  /// Detects if Vulkan is available (Windows/Linux/Android)
  Future<CapabilityDetectionResult> detectVulkan() async {
    if (_cache.containsKey(MLCapability.vulkan)) {
      return _cache[MLCapability.vulkan]!;
    }

    final platform = PlatformDetector.detectPlatform();
    if (platform != AIPlatform.windows &&
        platform != AIPlatform.linux &&
        platform != AIPlatform.android) {
      final result = CapabilityDetectionResult.unavailable(
        'Vulkan is only available on Windows, Linux, and Android',
      );
      _cache[MLCapability.vulkan] = result;
      return result;
    }

    // Vulkan detection requires checking for Vulkan runtime
    // This will be handled by llama.cpp
    // For now, we return unavailable by default
    try {
      final result = CapabilityDetectionResult.unavailable(
        'Vulkan detection requires runtime check by llama.cpp',
      );
      _cache[MLCapability.vulkan] = result;
      return result;
    } catch (e) {
      final result = CapabilityDetectionResult.unavailable(
        'Vulkan detection failed: $e',
      );
      _cache[MLCapability.vulkan] = result;
      return result;
    }
  }

  /// Gets all available capabilities for the current platform
  Future<Map<MLCapability, CapabilityDetectionResult>>
  detectAllCapabilities() async {
    final results = <MLCapability, CapabilityDetectionResult>{};

    // Detect platform-specific capabilities
    if (kIsWeb) {
      results[MLCapability.webGPU] = await detectWebGPU();
    } else {
      final platform = PlatformDetector.detectPlatform();

      if (platform == AIPlatform.android) {
        results[MLCapability.nnapi] = await detectNNAPI();
        results[MLCapability.vulkan] = await detectVulkan();
      } else if (platform == AIPlatform.windows) {
        results[MLCapability.directML] = await detectDirectML();
        results[MLCapability.cuda] = await detectCUDA();
        results[MLCapability.vulkan] = await detectVulkan();
      } else if (platform == AIPlatform.ios || platform == AIPlatform.macos) {
        results[MLCapability.metal] = await detectMetal();
      } else if (platform == AIPlatform.linux) {
        results[MLCapability.cuda] = await detectCUDA();
        results[MLCapability.vulkan] = await detectVulkan();
      }
    }

    return results;
  }

  /// Gets the best available hardware acceleration for the current platform
  Future<MLCapability?> getBestAcceleration() async {
    final capabilities = await detectAllCapabilities();

    // Priority order: WebGPU > Metal > DirectML > NNAPI > CUDA > Vulkan
    const priority = [
      MLCapability.webGPU,
      MLCapability.metal,
      MLCapability.directML,
      MLCapability.nnapi,
      MLCapability.cuda,
      MLCapability.vulkan,
    ];

    for (final capability in priority) {
      if (capabilities[capability]?.isAvailable == true) {
        return capability;
      }
    }

    return null;
  }

  /// Clears the capability detection cache
  void clearCache() {
    _cache.clear();
  }

  /// Gets a human-readable name for a capability
  static String getCapabilityName(MLCapability capability) {
    switch (capability) {
      case MLCapability.onnxRuntime:
        return 'ONNX Runtime';
      case MLCapability.llamaCpp:
        return 'llama.cpp';
      case MLCapability.transformersJs:
        return 'Transformers.js';
      case MLCapability.webLLM:
        return 'WebLLM';
      case MLCapability.nnapi:
        return 'NNAPI';
      case MLCapability.directML:
        return 'DirectML';
      case MLCapability.webGPU:
        return 'WebGPU';
      case MLCapability.metal:
        return 'Metal';
      case MLCapability.cuda:
        return 'CUDA';
      case MLCapability.vulkan:
        return 'Vulkan';
    }
  }
}
