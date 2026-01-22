import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Local HTTP server for Windows OAuth redirect handling
/// Listens on localhost:3000 for auth callback from FastAPI backend
class WindowsAuthServer {
  HttpServer? _server;
  final _completer = Completer<String>();
  final int port;

  WindowsAuthServer({this.port = 3000});

  /// Start the local server and wait for auth callback
  Future<String> waitForAuthCode() async {
    try {
      debugPrint('[WindowsAuthServer] Starting server on port $port...');
      
      // Start server on localhost
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      debugPrint('[WindowsAuthServer] Server started successfully on http://localhost:$port');

      // Listen for incoming requests
      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });

      // Wait for auth code (with timeout)
      return await _completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException('Authentication timed out');
        },
      );
    } catch (e) {
      debugPrint('[WindowsAuthServer] Error starting server: $e');
      await stop();
      rethrow;
    }
  }

  /// Handle incoming HTTP request
  void _handleRequest(HttpRequest request) async {
    debugPrint('[WindowsAuthServer] Received request: ${request.uri}');

    try {
      // Check if this is the auth callback
      if (request.uri.queryParameters.containsKey('code')) {
        final code = request.uri.queryParameters['code']!;
        debugPrint('[WindowsAuthServer] Auth code received: ${code.substring(0, 20)}...');

        // Send success response to browser
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_getSuccessHtml());
        await request.response.close();

        // Complete with the auth code
        if (!_completer.isCompleted) {
          _completer.complete(code);
        }

        // Stop server after a short delay to ensure response is sent
        Future.delayed(const Duration(milliseconds: 500), () {
          stop();
        });
      } else {
        // Unknown request
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Invalid request');
        await request.response.close();
      }
    } catch (e) {
      debugPrint('[WindowsAuthServer] Error handling request: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Server error');
      await request.response.close();
    }
  }

  /// Stop the server
  Future<void> stop() async {
    if (_server != null) {
      debugPrint('[WindowsAuthServer] Stopping server...');
      await _server!.close(force: true);
      _server = null;
      debugPrint('[WindowsAuthServer] Server stopped');
    }
  }

  /// HTML page shown in browser after successful authentication
  String _getSuccessHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Authentication Successful</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .container {
      text-align: center;
      background: white;
      padding: 50px;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      max-width: 500px;
    }
    .checkmark {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      display: block;
      stroke-width: 3;
      stroke: #4bb543;
      stroke-miterlimit: 10;
      margin: 0 auto 20px;
      box-shadow: inset 0px 0px 0px #4bb543;
      animation: fill .4s ease-in-out .4s forwards, scale .3s ease-in-out .9s both;
    }
    .checkmark__circle {
      stroke-dasharray: 166;
      stroke-dashoffset: 166;
      stroke-width: 3;
      stroke-miterlimit: 10;
      stroke: #4bb543;
      fill: none;
      animation: stroke 0.6s cubic-bezier(0.65, 0, 0.45, 1) forwards;
    }
    .checkmark__check {
      transform-origin: 50% 50%;
      stroke-dasharray: 48;
      stroke-dashoffset: 48;
      animation: stroke 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.8s forwards;
    }
    @keyframes stroke {
      100% {
        stroke-dashoffset: 0;
      }
    }
    @keyframes scale {
      0%, 100% {
        transform: none;
      }
      50% {
        transform: scale3d(1.1, 1.1, 1);
      }
    }
    @keyframes fill {
      100% {
        box-shadow: inset 0px 0px 0px 30px #4bb543;
      }
    }
    h1 {
      color: #333;
      margin: 20px 0 10px;
      font-size: 28px;
    }
    p {
      color: #666;
      font-size: 16px;
      line-height: 1.6;
    }
    .close-btn {
      margin-top: 30px;
      padding: 12px 30px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      border-radius: 25px;
      font-size: 16px;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(0,0,0,0.2);
      transition: transform 0.2s;
    }
    .close-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(0,0,0,0.3);
    }
  </style>
</head>
<body>
  <div class="container">
    <svg class="checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
      <circle class="checkmark__circle" cx="26" cy="26" r="25" fill="none"/>
      <path class="checkmark__check" fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8"/>
    </svg>
    <h1>Authentication Successful!</h1>
    <p>You have successfully signed in to ScholarMate.</p>
    <p>You can now close this window and return to the app.</p>
    <button class="close-btn" onclick="window.close()">Close Window</button>
  </div>
  <script>
    // Auto-close after 3 seconds
    setTimeout(function() {
      window.close();
    }, 3000);
  </script>
</body>
</html>
''';
  }
}
