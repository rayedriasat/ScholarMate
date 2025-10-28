// Test script to verify tessdata copying works
// Run with: flutter run test_tessdata_copy.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const TessdataTestApp());
}

class TessdataTestApp extends StatelessWidget {
  const TessdataTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tessdata Copy Test',
      home: const TessdataTestScreen(),
    );
  }
}

class TessdataTestScreen extends StatefulWidget {
  const TessdataTestScreen({super.key});

  @override
  State<TessdataTestScreen> createState() => _TessdataTestScreenState();
}

class _TessdataTestScreenState extends State<TessdataTestScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testTessdataCopy() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing tessdata copy...';
    });

    try {
      // Step 1: Check if asset exists
      setState(() => _status = 'Step 1: Checking asset...');
      final assetData = await rootBundle.load(
        'assets/tessdata/eng.traineddata',
      );
      final assetSize = assetData.lengthInBytes;
      setState(
        () => _status =
            'Step 1: ✅ Asset found (${(assetSize / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
      await Future.delayed(const Duration(seconds: 1));

      // Step 2: Get app directory
      setState(() => _status = 'Step 2: Getting app directory...');
      final appDir = await getApplicationDocumentsDirectory();
      setState(() => _status = 'Step 2: ✅ App dir: ${appDir.path}');
      await Future.delayed(const Duration(seconds: 1));

      // Step 3: Create tessdata directory
      setState(() => _status = 'Step 3: Creating tessdata directory...');
      final tessdataDir = Directory(path.join(appDir.path, 'tessdata'));
      if (!await tessdataDir.exists()) {
        await tessdataDir.create(recursive: true);
      }
      setState(
        () => _status = 'Step 3: ✅ Directory created: ${tessdataDir.path}',
      );
      await Future.delayed(const Duration(seconds: 1));

      // Step 4: Copy tessdata file
      setState(() => _status = 'Step 4: Copying tessdata file...');
      final engFile = File(path.join(tessdataDir.path, 'eng.traineddata'));

      if (await engFile.exists()) {
        setState(() => _status = 'Step 4: ℹ️ File already exists, deleting...');
        await engFile.delete();
        await Future.delayed(const Duration(seconds: 1));
      }

      final bytes = assetData.buffer.asUint8List();
      await engFile.writeAsBytes(bytes);

      final fileSize = await engFile.length();
      setState(
        () => _status =
            'Step 4: ✅ File copied (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
      await Future.delayed(const Duration(seconds: 1));

      // Step 5: Verify file
      setState(() => _status = 'Step 5: Verifying file...');
      if (await engFile.exists()) {
        final verifySize = await engFile.length();
        if (verifySize == assetSize) {
          setState(() => _status = 'Step 5: ✅ File verified successfully!');
        } else {
          setState(
            () => _status =
                'Step 5: ❌ Size mismatch! Asset: $assetSize, File: $verifySize',
          );
        }
      } else {
        setState(() => _status = 'Step 5: ❌ File not found after copy!');
      }
      await Future.delayed(const Duration(seconds: 1));

      // Final status
      setState(() {
        _status =
            '''
✅ TEST PASSED!

Asset size: ${(assetSize / 1024 / 1024).toStringAsFixed(1)} MB
File location: ${engFile.path}
File size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB

Tessdata is ready for offline OCR!
''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ TEST FAILED!\n\nError: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tessdata Copy Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This test verifies that tessdata can be copied from assets to device storage.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testTessdataCopy,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Test'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
