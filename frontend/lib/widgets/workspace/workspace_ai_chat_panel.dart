import 'package:flutter/material.dart';
import '../../models/drive_file.dart';
import '../../screens/ai_chat_screen.dart';

/// AI Chat panel wrapper for the workspace
/// Uses the existing AIChatScreen in embedded mode
class WorkspaceAiChatPanel extends StatelessWidget {
  final DriveFile? currentFile;
  final VoidCallback onClose;

  const WorkspaceAiChatPanel({
    super.key,
    this.currentFile,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AIChatScreen(
      preselectedFileId: currentFile?.id,
      preselectedFileName: currentFile?.name,
      isEmbedded: true,
      onClose: onClose,
    );
  }
}
