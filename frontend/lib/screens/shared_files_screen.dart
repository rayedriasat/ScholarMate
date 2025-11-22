import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sharing_service.dart';
import 'pdf_viewer_screen.dart';

/// Screen displaying files shared with the current user
class SharedFilesScreen extends StatefulWidget {
  const SharedFilesScreen({super.key});

  @override
  State<SharedFilesScreen> createState() => _SharedFilesScreenState();
}

class _SharedFilesScreenState extends State<SharedFilesScreen> {
  List<SharedFileInfo> _sharedFiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedFiles();
  }

  Future<void> _loadSharedFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sharingService = context.read<SharingService>();
      final sharedFiles = await sharingService.listSharedWithMe();

      if (mounted) {
        setState(() {
          _sharedFiles = sharedFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadSharedFiles();
  }

  void _openFile(SharedFileInfo fileInfo) {
    final file = fileInfo.toDriveFile();

    if (file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PdfViewerScreen(file: file)),
      );
    } else if (file.isFolder) {
      // TODO: Navigate to folder contents
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder navigation coming soon')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open ${file.extension ?? 'this'} files yet'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared with Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading shared files',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sharedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No shared files',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Files shared with you will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sharedFiles.length,
        itemBuilder: (context, index) {
          final fileInfo = _sharedFiles[index];
          final file = fileInfo.toDriveFile();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  file.isFolder
                      ? Icons.folder
                      : file.isPdf
                      ? Icons.picture_as_pdf
                      : Icons.insert_drive_file,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        fileInfo.permission == 'editor'
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fileInfo.permission == 'editor' ? 'Editor' : 'Viewer',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shared by ${fileInfo.ownerName ?? fileInfo.ownerEmail ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (file.size != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      file.formattedSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openFile(fileInfo),
            ),
          );
        },
      ),
    );
  }
}
