import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../database/database.dart';
import '../services/notebook_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// AI Studio tab with various AI tools
class NotebookAiStudioTab extends StatefulWidget {
  final String folderId;

  const NotebookAiStudioTab({super.key, required this.folderId});

  @override
  State<NotebookAiStudioTab> createState() => _NotebookAiStudioTabState();
}

class _NotebookAiStudioTabState extends State<NotebookAiStudioTab> {
  String? _selectedTool;
  List<NotebookAiOutput> _outputs = [];
  bool _isLoading = false;

  final List<_AiTool> _tools = [
    _AiTool(
      id: 'quiz',
      name: 'Quiz Generator',
      description: 'Generate practice questions from your materials',
      icon: Icons.quiz,
      color: Colors.blue,
    ),
    _AiTool(
      id: 'summary',
      name: 'Summarizer',
      description: 'Create concise summaries of your content',
      icon: Icons.summarize,
      color: Colors.green,
    ),
    _AiTool(
      id: 'mindmap',
      name: 'Mind Map',
      description: 'Generate visual concept maps',
      icon: Icons.account_tree,
      color: Colors.purple,
    ),
    _AiTool(
      id: 'flashcard',
      name: 'Flashcards',
      description: 'Create flashcards for revision',
      icon: Icons.style,
      color: Colors.orange,
    ),
    _AiTool(
      id: 'audio',
      name: 'Audio Review',
      description: 'Convert content to audio',
      icon: Icons.headphones,
      color: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOutputs();
  }

  Future<void> _loadOutputs() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<NotebookService>();
      final outputs = await service.getAiOutputs(
        widget.folderId,
        toolType: _selectedTool,
      );
      setState(() {
        _outputs = outputs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading outputs: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectTool(String toolId) {
    setState(() {
      _selectedTool = _selectedTool == toolId ? null : toolId;
    });
    _loadOutputs();
  }

  Future<void> _generateContent(String toolType) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating content...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final service = context.read<NotebookService>();
      final apiService = ApiService(); // Use singleton directly
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id ?? '';

      debugPrint('');
      debugPrint('=' * 60);
      debugPrint('🔵 AI STUDIO GENERATION DEBUG');
      debugPrint('=' * 60);
      debugPrint('🔵 Tool: $toolType');
      debugPrint('🔵 User ID: $userId');
      debugPrint('🔵 Folder ID: ${widget.folderId}');

      // Get folder files for context
      final files = await service.getFiles(widget.folderId);
      debugPrint('🔵 Found ${files.length} files in workspace');

      // Debug: Print all files
      for (var file in files) {
        debugPrint('   📄 File: ${file.name}, DriveID: ${file.driveFileId}');
      }

      final fileIds = files
          .where((f) => f.driveFileId != null)
          .map((f) => f.driveFileId!)
          .toList();

      debugPrint('🔵 File IDs with Drive links: ${fileIds.length}');
      debugPrint('🔵 Actual file IDs being sent: $fileIds');

      if (fileIds.isEmpty) {
        throw Exception(
          'No files with Drive links found in workspace.\n\n'
          'Please add files from Drive using the "Add from Drive" button in the Files tab.',
        );
      }

      debugPrint(
        '🔵 Calling API for $toolType generation with ${fileIds.length} file IDs...',
      );

      switch (toolType) {
        case 'quiz':
          try {
            debugPrint('🔵 Generating quiz with ${fileIds.length} files...');
            debugPrint('🔵 File IDs: $fileIds');
            final response = await apiService.generateQuiz(
              userId: userId,
              fileIds: fileIds,
              numQuestions: 5,
            );
            debugPrint('🟢 Quiz API response received');
            debugPrint('🟢 Response keys: ${response.keys}');
            debugPrint('🔵 Saving quiz to database...');
            await service.generateQuiz(
              folderId: widget.folderId,
              title: 'Quiz - ${DateTime.now().toString().substring(0, 16)}',
              questions: (response['questions'] as List)
                  .map(
                    (q) => {
                      'question': q['question'],
                      'options': q['options'],
                      'correct_index': q['correct_index'],
                      'explanation': q['explanation'],
                    },
                  )
                  .toList(),
            );
            debugPrint('🟢 Quiz saved successfully');
          } catch (e) {
            debugPrint('🔴 Quiz generation error: $e');
            throw Exception('Quiz generation failed: ${e.toString()}');
          }
          break;

        case 'summary':
          try {
            debugPrint('🔵 Generating summary with ${fileIds.length} files...');
            debugPrint('🔵 File IDs: $fileIds');
            final response = await apiService.generateSummary(
              userId: userId,
              fileIds: fileIds,
            );
            debugPrint('🟢 Summary API response received');
            debugPrint('🟢 Response keys: ${response.keys}');
            final summaryContent = {
              'summary': response['summary'],
              'key_points': response['key_points'],
            };
            debugPrint('🔵 Saving summary to database...');
            await service.generateSummary(
              folderId: widget.folderId,
              title: 'Summary - ${DateTime.now().toString().substring(0, 16)}',
              summary: jsonEncode(summaryContent),
            );
            debugPrint('🟢 Summary saved successfully');
          } catch (e) {
            debugPrint('🔴 Summary generation error: $e');
            throw Exception('Summary generation failed: ${e.toString()}');
          }
          break;

        case 'flashcard':
          try {
            debugPrint(
              '🔵 Generating flashcards with ${fileIds.length} files...',
            );
            debugPrint('🔵 File IDs: $fileIds');
            final response = await apiService.generateFlashcards(
              userId: userId,
              fileIds: fileIds,
              numCards: 10,
            );
            debugPrint('🟢 Flashcards API response received');
            debugPrint('🟢 Response keys: ${response.keys}');
            debugPrint('🔵 Saving flashcards to database...');
            await service.generateFlashcards(
              folderId: widget.folderId,
              title:
                  'Flashcards - ${DateTime.now().toString().substring(0, 16)}',
              flashcards: (response['flashcards'] as List)
                  .map((fc) => {'front': fc['front'], 'back': fc['back']})
                  .toList(),
            );
            debugPrint('🟢 Flashcards saved successfully');
          } catch (e) {
            debugPrint('🔴 Flashcard generation error: $e');
            throw Exception('Flashcard generation failed: ${e.toString()}');
          }
          break;

        case 'mindmap':
          // Mind map generation not yet implemented in backend
          await service.generateMindMap(
            folderId: widget.folderId,
            title: 'Mind Map - ${DateTime.now().toString().substring(0, 16)}',
            mindMapData: {
              'root': 'Main Topic',
              'children': [
                {'name': 'Subtopic 1'},
                {'name': 'Subtopic 2'},
              ],
            },
          );
          break;

        case 'audio':
          // Audio generation not yet implemented
          await service.generateAudioReview(
            folderId: widget.folderId,
            title:
                'Audio Review - ${DateTime.now().toString().substring(0, 16)}',
            audioUrl: '',
            transcript: 'Audio generation coming soon',
          );
          break;
      }

      await _loadOutputs();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content generated successfully!')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 Generation error: $e');
      debugPrint('🔴 Stack trace: $stackTrace');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Generation Failed'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Error Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(e.toString()),
                  const SizedBox(height: 16),
                  const Text(
                    'Troubleshooting:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Ensure files are added to workspace'),
                  const Text('2. Verify files are indexed in main app'),
                  const Text('3. Check API key is configured'),
                  const Text('4. Ensure backend is running'),
                  const Text('5. Check network connection'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Instruction banner
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Long press any tool to generate content',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Fixed height container for tool grid to prevent overflow
        SizedBox(
          height: 280, // Fixed height for 2 rows of tools
          child: _buildToolGrid(),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _outputs.isEmpty
              ? _buildEmptyState()
              : _buildOutputList(),
        ),
      ],
    );
  }

  Widget _buildToolGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(), // Allow scrolling if needed
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        final isSelected = _selectedTool == tool.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? tool.color.withOpacity(0.1) : null,
          child: InkWell(
            onTap: () => _selectTool(tool.id),
            onLongPress: () => _generateContent(tool.id),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tool.icon, size: 28, color: tool.color),
                  const SizedBox(height: 6),
                  Text(
                    tool.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      tool.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No AI outputs yet'),
          const SizedBox(height: 8),
          Text(
            'Long press a tool to generate content',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _outputs.length,
      itemBuilder: (context, index) {
        final output = _outputs[index];
        final tool = _tools.firstWhere((t) => t.id == output.toolType);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: tool.color.withOpacity(0.2),
              child: Icon(tool.icon, color: tool.color),
            ),
            title: Text(output.title),
            subtitle: Text(_formatDate(output.createdAt)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteOutput(output),
            ),
            onTap: () => _viewOutput(output),
          ),
        );
      },
    );
  }

  Future<void> _deleteOutput(NotebookAiOutput output) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Output'),
        content: Text('Are you sure you want to delete "${output.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = context.read<NotebookService>();
        await service.deleteAiOutput(output.id);
        await _loadOutputs();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting output: $e')));
        }
      }
    }
  }

  void _viewOutput(NotebookAiOutput output) {
    Widget contentWidget;

    try {
      switch (output.toolType) {
        case 'quiz':
          contentWidget = _buildQuizView(output.content);
          break;
        case 'summary':
          contentWidget = _buildSummaryView(output.content);
          break;
        case 'flashcard':
          contentWidget = _buildFlashcardView(output.content);
          break;
        default:
          contentWidget = Text(output.content);
      }
    } catch (e) {
      contentWidget = Text('Error displaying content: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(output.title)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: contentWidget),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      ),
    );
  }

  Widget _buildQuizView(String content) {
    try {
      final questions = jsonDecode(content) as List;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: questions.asMap().entries.map((entry) {
          final index = entry.key;
          final q = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['question'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(q['options'] as List).asMap().entries.map((opt) {
                    final optIndex = opt.key;
                    final optText = opt.value;
                    final isCorrect = optIndex == q['correct_index'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isCorrect ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${String.fromCharCode(65 + optIndex)}. $optText',
                              style: TextStyle(
                                fontWeight: isCorrect
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCorrect ? Colors.green : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (q['explanation'] != null) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Explanation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(q['explanation']),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return Text('Error parsing quiz: $e');
    }
  }

  Widget _buildSummaryView(String content) {
    try {
      final data = jsonDecode(content);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(data['summary'] ?? content),
          if (data['key_points'] != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Key Points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(data['key_points'] as List).map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 18)),
                    Expanded(child: Text(point)),
                  ],
                ),
              );
            }),
          ],
        ],
      );
    } catch (e) {
      return Text(content);
    }
  }

  Widget _buildFlashcardView(String content) {
    try {
      final flashcards = jsonDecode(content) as List;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: flashcards.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Front:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['front'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Back:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card['back'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return Text('Error parsing flashcards: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _AiTool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _AiTool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
