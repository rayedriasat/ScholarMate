import 'package:flutter/material.dart';
import '../models/drive_file.dart';
import 'pdf_workspace_screen.dart';

/// Legacy PDF viewer - redirects to new workspace
/// Kept for backward compatibility with existing navigation
class PdfViewerScreen extends StatefulWidget {
  final DriveFile? file;
  final String? fileId;
  final String? fileName;
  final int? initialPage;
  final String? searchQuery;
  final String? highlightText;

  const PdfViewerScreen({
    super.key,
    this.file,
    this.fileId,
    this.fileName,
    this.initialPage,
    this.searchQuery,
    this.highlightText,
  }) : assert(
         file != null || (fileId != null && fileName != null),
         'Either file or both fileId and fileName must be provided',
       );

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  @override
  Widget build(BuildContext context) {
    // Redirect to new workspace screen
    return PdfWorkspaceScreen(
      initialFile: widget.file,
      initialFileId: widget.fileId,
      initialFileName: widget.fileName,
      initialPage: widget.initialPage,
      searchQuery: widget.searchQuery,
      highlightText: widget.highlightText,
    );
  }
}
