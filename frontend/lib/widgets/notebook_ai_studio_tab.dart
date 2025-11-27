import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import '../database/database.dart';
import '../services/notebook_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../screens/quiz_taking_screen.dart';
import '../screens/flashcard_view_screen.dart';

/// AI Studio tab with various AI tools
class NotebookAiStudioTab extends StatefulWidget {
  final String folderId;
  final Function(String content, String title, String toolType)? onViewContent;

  const NotebookAiStudioTab({
    super.key,
    required this.folderId,
    this.onViewContent,
  });

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
            // Ask for number of questions
            int numQuestions = 5;
            if (mounted) {
              // Close loading dialog first
              Navigator.pop(context);

              final selected = await showDialog<int>(
                context: context,
                builder: (context) => _QuizQuestionCountDialog(),
              );

              if (selected == null) return; // User cancelled
              numQuestions = selected;

              // Show loading dialog again
              if (!context.mounted) return;
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
            }

            debugPrint('🔵 Generating quiz with ${fileIds.length} files...');
            debugPrint('🔵 File IDs: $fileIds');
            final response = await apiService.generateQuiz(
              userId: userId,
              fileIds: fileIds,
              numQuestions: numQuestions,
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
          try {
            debugPrint(
              '🔵 Generating audio review with ${fileIds.length} files...',
            );
            debugPrint('🔵 File IDs: $fileIds');
            final response = await apiService.generateAudioReview(
              userId: userId,
              fileIds: fileIds,
            );
            debugPrint('🟢 Audio API response received');
            debugPrint('🟢 Response keys: ${response.keys}');

            // Extract segments and title from response
            final segments = response['segments'] as List;
            final title =
                response['title'] as String? ??
                'Audio Review - ${DateTime.now().toString().substring(0, 16)}';

            debugPrint('🔵 Saving audio review to database...');
            debugPrint('🔵 Title: $title');
            debugPrint('🔵 Segments: ${segments.length}');

            await service.generateAudioReview(
              folderId: widget.folderId,
              title: title,
              segments: segments.cast<Map<String, dynamic>>(),
            );
            debugPrint('🟢 Audio review saved successfully');
          } catch (e) {
            debugPrint('🔴 Audio generation error: $e');
            throw Exception('Audio generation failed: ${e.toString()}');
          }
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
          color: isSelected ? tool.color.withValues(alpha: 0.1) : null,
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
              backgroundColor: tool.color.withValues(alpha: 0.2),
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
    // If callback is provided and tool is supported, delegate to parent
    // Note: Audio is handled in dialog, not delegated to parent
    if (widget.onViewContent != null &&
        (output.toolType == 'flashcard' || output.toolType == 'quiz')) {
      widget.onViewContent!(output.content, output.title, output.toolType);
      return;
    }

    Widget contentWidget;

    try {
      switch (output.toolType) {
        case 'quiz':
          contentWidget = _buildQuizView(output.content, output.title);
          break;
        case 'summary':
          contentWidget = _buildSummaryView(output.content);
          break;
        case 'flashcard':
          contentWidget = _buildFlashcardView(output.content, output.title);
          break;
        case 'audio':
          contentWidget = _buildAudioView(output.content, output.title);
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

  Widget _buildQuizView(String content, String title) {
    try {
      final questions = (jsonDecode(content) as List)
          .cast<Map<String, dynamic>>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exam Mode Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.school, size: 32, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  '${questions.length} Questions Generated',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Test your knowledge with Exam Mode',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    if (widget.onViewContent != null) {
                      // Use callback to display in chat area
                      widget.onViewContent!(content, title, 'quiz');
                    } else {
                      // Fallback: navigate to dedicated screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizTakingScreen(
                            title: title,
                            questions: questions,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Exam'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Preview Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...questions.asMap().entries.map((entry) {
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
          }),
        ],
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

  Widget _buildFlashcardView(String content, String title) {
    try {
      final flashcards = (jsonDecode(content) as List)
          .cast<Map<String, dynamic>>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flashcard Mode Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.style, size: 32, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  '${flashcards.length} Flashcards Generated',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review key concepts with Flashcards',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashcardViewScreen(
                          title: title,
                          flashcards: flashcards,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Review'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Preview Cards',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...flashcards.asMap().entries.map((entry) {
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
                        color: Colors.blue.withValues(alpha: 0.1),
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
                        color: Colors.green.withValues(alpha: 0.1),
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
          }),
        ],
      );
    } catch (e) {
      return Text('Error parsing flashcards: $e');
    }
  }

  Widget _buildAudioView(String content, String title) {
    try {
      final data = jsonDecode(content);
      final segments = (data['segments'] as List).cast<Map<String, dynamic>>();

      return _AudioReviewPlayer(
        title: data['title'] ?? title,
        segments: segments,
      );
    } catch (e) {
      return Text('Error parsing audio content: $e');
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

class _QuizQuestionCountDialog extends StatefulWidget {
  @override
  State<_QuizQuestionCountDialog> createState() =>
      _QuizQuestionCountDialogState();
}

class _QuizQuestionCountDialogState extends State<_QuizQuestionCountDialog> {
  double _questionCount = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiz Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Number of Questions'),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_questionCount.round()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _questionCount,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: _questionCount.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _questionCount = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select between 5 and 20 questions',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _questionCount.round()),
          child: const Text('Generate'),
        ),
      ],
    );
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

/// Audio review player with TTS
class _AudioReviewPlayer extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> segments;

  const _AudioReviewPlayer({required this.title, required this.segments});

  @override
  State<_AudioReviewPlayer> createState() => _AudioReviewPlayerState();
}

class _AudioReviewPlayerState extends State<_AudioReviewPlayer> {
  final FlutterTts _tts = FlutterTts();
  int _currentSegmentIndex = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 1.0;
  final double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(1.0);

      _tts.setCompletionHandler(() {
        if (_isPlaying && !_isPaused) {
          _playNextSegment();
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        setState(() {
          _isPlaying = false;
          _isPaused = false;
        });
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  @override
  void dispose() {
    _stopPlayback();
    _tts.stop();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isPaused) {
      // Resume from current segment
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
      await _playSegment(_currentSegmentIndex);
    } else {
      // Start from beginning
      setState(() {
        _isPlaying = true;
        _isPaused = false;
        _currentSegmentIndex = 0;
      });
      await _playSegment(0);
    }
  }

  Future<void> _playSegment(int index) async {
    if (index >= widget.segments.length || !_isPlaying) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _currentSegmentIndex = 0;
      });
      return;
    }

    setState(() => _currentSegmentIndex = index);

    final segment = widget.segments[index];
    final speaker = segment['speaker'] as String;
    final text = segment['text'] as String;

    try {
      // Adjust voice slightly for different speakers
      final isHost1 =
          speaker.contains('1') || speaker.toLowerCase().contains('alex');
      await _tts.setPitch(isHost1 ? 1.0 : 1.1);

      // Speak the text
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Error playing segment: $e');
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
    }
  }

  void _playNextSegment() {
    if (_isPlaying && !_isPaused) {
      final nextIndex = _currentSegmentIndex + 1;
      if (nextIndex < widget.segments.length) {
        _playSegment(nextIndex);
      } else {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _currentSegmentIndex = 0;
        });
      }
    }
  }

  Future<void> _pausePlayback() async {
    await _tts.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  Future<void> _stopPlayback() async {
    await _tts.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentSegmentIndex = 0;
    });
  }

  Future<void> _skipToSegment(int index) async {
    await _stopPlayback();
    setState(() => _currentSegmentIndex = index);
  }

  Future<void> _updateSpeechRate(double rate) async {
    setState(() => _speechRate = rate);
    await _tts.setSpeechRate(rate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.headphones, size: 32, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.segments.length} segments',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Progress indicator
              Row(
                children: [
                  Text(
                    'Segment ${_currentSegmentIndex + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentSegmentIndex.toDouble(),
                      min: 0,
                      max: (widget.segments.length - 1).toDouble(),
                      divisions: widget.segments.length - 1,
                      onChanged: (value) {
                        _skipToSegment(value.round());
                      },
                    ),
                  ),
                  Text(
                    '${widget.segments.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Speech rate control
              Row(
                children: [
                  const Icon(Icons.speed, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_speechRate.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _speechRate,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${_speechRate.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        _updateSpeechRate(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: _currentSegmentIndex > 0
                        ? () => _skipToSegment(_currentSegmentIndex - 1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isPlaying ? _pausePlayback : _playAudio,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      _isPlaying ? 'Pause' : (_isPaused ? 'Resume' : 'Play'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(120, 48),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _isPlaying || _isPaused ? _stopPlayback : null,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: _currentSegmentIndex < widget.segments.length - 1
                        ? () => _skipToSegment(_currentSegmentIndex + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Conversation Script',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Segments list
        ...widget.segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final speaker = segment['speaker'] as String;
          final text = segment['text'] as String;
          final isHost1 =
              speaker.contains('1') || speaker.toLowerCase().contains('alex');
          final isCurrent = index == _currentSegmentIndex;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isCurrent ? Colors.red.withOpacity(0.1) : null,
            elevation: isCurrent ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isHost1
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        child: Icon(
                          isHost1 ? Icons.person : Icons.person_outline,
                          color: isHost1 ? Colors.blue : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          speaker,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isHost1 ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                      if (isCurrent && _isPlaying)
                        const Icon(
                          Icons.volume_up,
                          color: Colors.red,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: isCurrent
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a podcast-style conversation about your materials. '
                  'Use the player controls to listen through the segments.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
