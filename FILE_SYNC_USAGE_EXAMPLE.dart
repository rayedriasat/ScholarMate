// Example: How to use FileSyncService in a PDF viewer screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/file_sync_service.dart';
import '../services/drive_service.dart';
import '../widgets/file_sync_indicator.dart';

class PDFViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late FileSyncService _syncService;
  late DriveService _driveService;
  StreamSubscription<DriveFile>? _updateSubscription;

  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;

  final PdfViewerController _pdfController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _syncService = context.read<FileSyncService>();
    _driveService = context.read<DriveService>();

    // Start watching file for updates
    _syncService.watchFile(widget.fileId);

    // Listen for file updates
    _updateSubscription = _syncService
        .getFileUpdateStream(widget.fileId)
        .listen(_handleFileUpdate);

    // Load initial PDF
    _loadPDF();
  }

  @override
  void dispose() {
    // Stop watching file
    _syncService.unwatchFile(widget.fileId);
    _updateSubscription?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  /// Load PDF from Drive (checks for updates automatically)
  Future<void> _loadPDF({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes = await _driveService.downloadFile(
        widget.fileId,
        forceRefresh: forceRefresh,
        onProgress: (progress) {
          // Optional: Show download progress
          debugPrint(
            'Download progress: ${(progress * 100).toStringAsFixed(0)}%',
          );
        },
      );

      if (bytes != null) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Handle file update notification from sync service
  void _handleFileUpdate(DriveFile updatedFile) {
    debugPrint('File updated: ${updatedFile.name}');

    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${updatedFile.name} was updated'),
        action: SnackBarAction(
          label: 'Reload',
          onPressed: () => _loadPDF(forceRefresh: true),
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    // Optional: Auto-reload (be careful with this as it might interrupt user)
    // _loadPDF(forceRefresh: true);
  }

  /// Manual refresh triggered by user
  Future<void> _handleManualRefresh() async {
    await _loadPDF(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          // Sync indicator with manual refresh button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FileSyncIndicator(
              fileId: widget.fileId,
              onRefresh: _handleManualRefresh,
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: SyncFloatingActionButton(
        fileId: widget.fileId,
        onSyncComplete: () {
          // Reload PDF after manual sync
          _loadPDF(forceRefresh: true);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadPDF(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pdfBytes == null) {
      return const Center(child: Text('No PDF data'));
    }

    return SfPdfViewer.memory(
      _pdfBytes!,
      controller: _pdfController,
      onDocumentLoaded: (details) {
        debugPrint('PDF loaded: ${details.document.pages.count} pages');
      },
      onDocumentLoadFailed: (details) {
        setState(() {
          _error = details.error;
        });
      },
    );
  }
}

// ============================================================================
// Alternative: Simpler implementation without auto-reload
// ============================================================================

class SimplePDFViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;

  const SimplePDFViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  State<SimplePDFViewerScreen> createState() => _SimplePDFViewerScreenState();
}

class _SimplePDFViewerScreenState extends State<SimplePDFViewerScreen> {
  @override
  void initState() {
    super.initState();
    // Start watching file (sync service will check for updates automatically)
    context.read<FileSyncService>().watchFile(widget.fileId);
  }

  @override
  void dispose() {
    // Stop watching file
    context.read<FileSyncService>().unwatchFile(widget.fileId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          // Simple sync badge
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FileSyncBadge(fileId: widget.fileId, showLastSync: true),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List?>(
        future: context.read<DriveService>().downloadFile(widget.fileId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No PDF data'));
          }

          return SfPdfViewer.memory(snapshot.data!);
        },
      ),
    );
  }
}

// ============================================================================
// Example: File list with sync badges
// ============================================================================

class FileListScreen extends StatelessWidget {
  final List<DriveFile> files;

  const FileListScreen({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];

        return ListTile(
          leading: Icon(
            file.isPdf ? Icons.picture_as_pdf : Icons.folder,
            color: file.isPdf ? Colors.red : Colors.blue,
          ),
          title: Text(file.name),
          subtitle: Text('Modified: ${_formatDate(file.modifiedTime)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show sync badge for PDF files
              if (file.isPdf)
                FileSyncBadge(fileId: file.id, showLastSync: true),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            if (file.isPdf) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PDFViewerScreen(fileId: file.id, fileName: file.name),
                ),
              );
            }
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// Example: Configure sync interval
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.read<FileSyncService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Sync Interval'),
            subtitle: Text('Current: ${syncService.syncInterval.inSeconds}s'),
          ),
          RadioListTile<int>(
            title: const Text('Real-time (10 seconds)'),
            subtitle: const Text(
              'Best for collaboration, higher battery usage',
            ),
            value: 10,
            groupValue: syncService.syncInterval.inSeconds,
            onChanged: (value) {
              syncService.syncInterval = Duration(seconds: value!);
            },
          ),
          RadioListTile<int>(
            title: const Text('Normal (30 seconds)'),
            subtitle: const Text('Balanced performance'),
            value: 30,
            groupValue: syncService.syncInterval.inSeconds,
            onChanged: (value) {
              syncService.syncInterval = Duration(seconds: value!);
            },
          ),
          RadioListTile<int>(
            title: const Text('Battery Saver (60 seconds)'),
            subtitle: const Text('Lower battery usage'),
            value: 60,
            groupValue: syncService.syncInterval.inSeconds,
            onChanged: (value) {
              syncService.syncInterval = Duration(seconds: value!);
            },
          ),
        ],
      ),
    );
  }
}
