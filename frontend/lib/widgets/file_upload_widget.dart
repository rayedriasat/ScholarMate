import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/drive_service.dart';

/// Widget for handling file uploads with progress tracking
class FileUploadWidget extends StatefulWidget {
  final String parentFolderId;
  final DriveService driveService;
  final VoidCallback? onUploadComplete;

  const FileUploadWidget({
    super.key,
    required this.parentFolderId,
    required this.driveService,
    this.onUploadComplete,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final List<UploadTask> _uploadTasks = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upload button
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _pickAndUploadFiles,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Files'),
        ),

        // Upload progress
        if (_uploadTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _uploadTasks.length,
              itemBuilder: (context, index) {
                final task = _uploadTasks[index];
                return _buildUploadTaskCard(task);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadTaskCard(UploadTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (task.status == UploadStatus.uploading)
                  IconButton(
                    icon: const Icon(Icons.cancel, size: 20),
                    onPressed: () => _cancelUpload(task),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(task),
                  style: TextStyle(fontSize: 12, color: _getStatusColor(task)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(UploadTask task) {
    switch (task.status) {
      case UploadStatus.pending:
        return 'Pending';
      case UploadStatus.uploading:
        return '${(task.progress * 100).toInt()}%';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(UploadTask task) {
    switch (task.status) {
      case UploadStatus.pending:
        return Colors.orange;
      case UploadStatus.uploading:
        return Colors.blue;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
      case UploadStatus.cancelled:
        return Colors.grey;
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'md', 'markdown', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        await _uploadFiles(result.files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFiles(List<PlatformFile> files) async {
    setState(() {
      _isUploading = true;
      for (final file in files) {
        _uploadTasks.add(
          UploadTask(
            fileName: file.name,
            file: file,
            status: UploadStatus.pending,
          ),
        );
      }
    });

    for (final task in _uploadTasks.where(
      (t) => t.status == UploadStatus.pending,
    )) {
      if (task.status == UploadStatus.cancelled) continue;

      await _uploadSingleFile(task);
    }

    setState(() {
      _isUploading = false;
    });

    // Clear completed tasks after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _uploadTasks.removeWhere(
            (task) =>
                task.status == UploadStatus.completed ||
                task.status == UploadStatus.cancelled,
          );
        });
        widget.onUploadComplete?.call();
      }
    });
  }

  Future<void> _uploadSingleFile(UploadTask task) async {
    try {
      setState(() {
        task.status = UploadStatus.uploading;
        task.progress = 0.0;
      });

      if (kIsWeb) {
        // For web, upload from bytes
        if (task.file.bytes == null) {
          throw Exception('File bytes not available on web');
        }

        // Simulate progress updates
        for (int i = 0; i <= 90; i += 10) {
          if (task.status == UploadStatus.cancelled) return;

          setState(() {
            task.progress = i / 100.0;
          });

          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Perform actual upload
        await widget.driveService.uploadFileFromBytes(
          task.file.bytes!,
          task.fileName,
          widget.parentFolderId,
          onProgress: (progress) {
            if (mounted && task.status == UploadStatus.uploading) {
              setState(() {
                task.progress = 0.9 + (progress * 0.1);
              });
            }
          },
        );
      } else {
        // For mobile/desktop, use the file path
        if (task.file.path == null) {
          throw Exception('File path not available');
        }
        final file = File(task.file.path!);

        // Simulate progress updates
        for (int i = 0; i <= 90; i += 10) {
          if (task.status == UploadStatus.cancelled) return;

          setState(() {
            task.progress = i / 100.0;
          });

          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Perform actual upload
        await widget.driveService.uploadFile(
          file,
          widget.parentFolderId,
          customName: task.fileName,
          onProgress: (progress) {
            if (mounted && task.status == UploadStatus.uploading) {
              setState(() {
                task.progress = 0.9 + (progress * 0.1);
              });
            }
          },
        );
      }

      setState(() {
        task.status = UploadStatus.completed;
        task.progress = 1.0;
      });
    } catch (e) {
      setState(() {
        task.status = UploadStatus.failed;
        task.error = e.toString();
      });
    }
  }

  void _cancelUpload(UploadTask task) {
    setState(() {
      task.status = UploadStatus.cancelled;
    });
  }
}

/// Represents an upload task
class UploadTask {
  final String fileName;
  final PlatformFile file;
  UploadStatus status;
  double progress;
  String? error;

  UploadTask({
    required this.fileName,
    required this.file,
    required this.status,
    this.progress = 0.0,
    this.error,
  });
}

/// Upload status enumeration
enum UploadStatus { pending, uploading, completed, failed, cancelled }
