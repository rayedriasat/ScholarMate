import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Enum representing the supported platforms for offline AI
enum AIPlatform { android, windows, web, ios, macos, linux, unsupported }

/// Enum representing ML backend capabilities
enum MLCapability {
  onnxRuntime,
  llamaCpp,
  transformersJs,
  webLLM,
  nnapi,
  directML,
  webGPU,
  metal,
  cuda,
  vulkan,
}

/// Platform detection utility for offline AI features
class PlatformDetector {
  /// Detects the current platform
  static AIPlatform detectPlatform() {
    if (kIsWeb) {
      return AIPlatform.web;
    }

    if (Platform.isAndroid) {
      return AIPlatform.android;
    }

    if (Platform.isWindows) {
      return AIPlatform.windows;
    }

    if (Platform.isIOS) {
      return AIPlatform.ios;
    }

    if (Platform.isMacOS) {
      return AIPlatform.macos;
    }

    if (Platform.isLinux) {
      return AIPlatform.linux;
    }

    return AIPlatform.unsupported;
  }

  /// Checks if the current platform is a native platform (Android/Windows/iOS/macOS/Linux)
  static bool isNativePlatform() {
    final platform = detectPlatform();
    return platform == AIPlatform.android ||
        platform == AIPlatform.windows ||
        platform == AIPlatform.ios ||
        platform == AIPlatform.macos ||
        platform == AIPlatform.linux;
  }

  /// Checks if the current platform is web
  static bool isWebPlatform() {
    return detectPlatform() == AIPlatform.web;
  }

  /// Checks if the current platform supports ONNX Runtime
  static bool supportsOnnxRuntime() {
    final platform = detectPlatform();
    return platform == AIPlatform.android ||
        platform == AIPlatform.windows ||
        platform == AIPlatform.ios ||
        platform == AIPlatform.macos ||
        platform == AIPlatform.linux;
  }

  /// Checks if the current platform supports llama.cpp
  static bool supportsLlamaCpp() {
    final platform = detectPlatform();
    return platform == AIPlatform.android ||
        platform == AIPlatform.windows ||
        platform == AIPlatform.ios ||
        platform == AIPlatform.macos ||
        platform == AIPlatform.linux;
  }

  /// Checks if the current platform supports Transformers.js
  static bool supportsTransformersJs() {
    return isWebPlatform();
  }

  /// Checks if the current platform supports WebLLM
  static bool supportsWebLLM() {
    return isWebPlatform();
  }

  /// Gets the recommended ML backend for embeddings on the current platform
  static String getRecommendedEmbeddingBackend() {
    if (isWebPlatform()) {
      return 'Transformers.js';
    }
    if (isNativePlatform()) {
      return 'ONNX Runtime';
    }
    return 'None';
  }

  /// Gets the recommended ML backend for LLM on the current platform
  static String getRecommendedLLMBackend() {
    if (isWebPlatform()) {
      return 'WebLLM';
    }
    if (isNativePlatform()) {
      return 'llama.cpp';
    }
    return 'None';
  }

  /// Gets a human-readable platform name
  static String getPlatformName() {
    switch (detectPlatform()) {
      case AIPlatform.android:
        return 'Android';
      case AIPlatform.windows:
        return 'Windows';
      case AIPlatform.web:
        return 'Web';
      case AIPlatform.ios:
        return 'iOS';
      case AIPlatform.macos:
        return 'macOS';
      case AIPlatform.linux:
        return 'Linux';
      case AIPlatform.unsupported:
        return 'Unsupported';
    }
  }
}
