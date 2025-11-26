import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardViewScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> flashcards;

  const FlashcardViewScreen({
    super.key,
    required this.title,
    required this.flashcards,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FlashcardView(flashcards: flashcards),
    );
  }
}

class FlashcardView extends StatefulWidget {
  final List<Map<String, dynamic>> flashcards;
  final VoidCallback? onClose;

  const FlashcardView({super.key, required this.flashcards, this.onClose});

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  late PageController _pageController;
  int _currentIndex = 0;

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
                  'Flashcard Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        LinearProgressIndicator(
          value: (widget.flashcards.isNotEmpty)
              ? (_currentIndex + 1) / widget.flashcards.length
              : 0,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Card ${_currentIndex + 1} of ${widget.flashcards.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.flashcards.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: _FlashcardItem(
                  front: widget.flashcards[index]['front'] ?? '',
                  back: widget.flashcards[index]['back'] ?? '',
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.tonalIcon(
                onPressed: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              FilledButton.tonalIcon(
                onPressed: _currentIndex < widget.flashcards.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlashcardItem extends StatefulWidget {
  final String front;
  final String back;

  const _FlashcardItem({required this.front, required this.back});

  @override
  State<_FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<_FlashcardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFrontVisible = angle < pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? _buildCardSide(widget.front, true)
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardSide(widget.back, false),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(String text, bool isFront) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isFront
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primaryContainer,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFront ? 'Question' : 'Answer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isFront
                    ? Colors.grey
                    : Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isFront
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              isFront ? 'Tap to flip' : 'Tap to flip back',
              style: TextStyle(
                fontSize: 12,
                color: isFront
                    ? Colors.grey[400]
                    : Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
