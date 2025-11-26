import 'package:flutter/material.dart';

import 'quiz_result_screen.dart';

class QuizTakingScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> questions;

  const QuizTakingScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: QuizView(
        title: title,
        questions: questions,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

class QuizView extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> questions;
  final VoidCallback? onClose;

  const QuizView({
    super.key,
    required this.title,
    required this.questions,
    this.onClose,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentQuestionIndex = 0;
  // Map to store selected option index for each question
  final Map<int, int> _userAnswers = {};
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(int optionIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitQuiz() {
    // Check if all questions are answered
    if (_userAnswers.length < widget.questions.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Quiz'),
          content: Text(
            'You have answered ${_userAnswers.length} out of ${widget.questions.length} questions. Are you sure you want to submit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToResults();
              },
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
    } else {
      _navigateToResults();
    }
  }

  void _navigateToResults() {
    // If we are in a standalone screen (Navigator can pop), we might want to replace.
    // But if embedded, we just push the result screen or handle it differently.
    // For now, we'll push the result screen on top of the current context.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          title: widget.title,
          questions: widget.questions,
          userAnswers: _userAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.onClose != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                const Text(
                  'Quiz Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / widget.questions.length,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        // Question Counter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Exam Mode',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Disable swipe to enforce navigation buttons
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(widget.questions[index], index);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                OutlinedButton.icon(
                  onPressed: _previousQuestion,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                )
              else
                const SizedBox(width: 100), // Spacer to keep alignment

              const Spacer(),

              FilledButton.icon(
                onPressed: _nextQuestion,
                label: Text(
                  _currentQuestionIndex == widget.questions.length - 1
                      ? 'Submit'
                      : 'Next',
                ),
                icon: Icon(
                  _currentQuestionIndex == widget.questions.length - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                ),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int questionIndex) {
    final options = (question['options'] as List).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = _userAnswers[questionIndex] == optionIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _handleOptionSelected(optionIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.05)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
