/// Typing indicator widget for showing when users are typing comments
library;

import 'package:flutter/material.dart';
import 'dart:async';

/// Model for tracking typing users
class TypingUser {
  final String userId;
  final String userName;
  final int? pageNumber;
  final DateTime lastTypingTime;

  TypingUser({
    required this.userId,
    required this.userName,
    this.pageNumber,
    DateTime? lastTypingTime,
  }) : lastTypingTime = lastTypingTime ?? DateTime.now();

  TypingUser copyWith({
    String? userId,
    String? userName,
    int? pageNumber,
    DateTime? lastTypingTime,
  }) {
    return TypingUser(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      pageNumber: pageNumber ?? this.pageNumber,
      lastTypingTime: lastTypingTime ?? this.lastTypingTime,
    );
  }
}

/// Widget that displays typing indicators
class TypingIndicator extends StatefulWidget {
  final List<TypingUser> typingUsers;
  final int? currentPage;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    this.currentPage,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.typingUsers.isNotEmpty) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.typingUsers.isNotEmpty && oldWidget.typingUsers.isEmpty) {
      _animationController.forward();
    } else if (widget.typingUsers.isEmpty && oldWidget.typingUsers.isNotEmpty) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter users typing on current page if page is specified
    final relevantUsers = widget.currentPage != null
        ? widget.typingUsers
              .where(
                (u) =>
                    u.pageNumber == null || u.pageNumber == widget.currentPage,
              )
              .toList()
        : widget.typingUsers;

    if (relevantUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingAnimation(),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _buildTypingText(relevantUsers),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[900],
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return SizedBox(
      width: 24,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _TypingDot(delay: Duration(milliseconds: index * 200));
        }),
      ),
    );
  }

  String _buildTypingText(List<TypingUser> users) {
    if (users.length == 1) {
      return '${users[0].userName} is typing...';
    } else if (users.length == 2) {
      return '${users[0].userName} and ${users[1].userName} are typing...';
    } else {
      return '${users[0].userName} and ${users.length - 1} others are typing...';
    }
  }
}

/// Animated dot for typing indicator
class _TypingDot extends StatefulWidget {
  final Duration delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[700]!.withValues(
              alpha: 0.3 + (_animation.value * 0.7),
            ),
          ),
        );
      },
    );
  }
}

/// Manager for tracking typing users with automatic timeout
class TypingIndicatorManager extends ChangeNotifier {
  final Map<String, TypingUser> _typingUsers = {};
  final Duration _typingTimeout;
  Timer? _cleanupTimer;

  TypingIndicatorManager({Duration typingTimeout = const Duration(seconds: 3)})
    : _typingTimeout = typingTimeout {
    _startCleanupTimer();
  }

  List<TypingUser> get typingUsers => _typingUsers.values.toList();

  /// Add or update a typing user
  void setUserTyping({
    required String userId,
    required String userName,
    int? pageNumber,
  }) {
    _typingUsers[userId] = TypingUser(
      userId: userId,
      userName: userName,
      pageNumber: pageNumber,
      lastTypingTime: DateTime.now(),
    );
    notifyListeners();
  }

  /// Remove a typing user
  void setUserStoppedTyping(String userId) {
    if (_typingUsers.remove(userId) != null) {
      notifyListeners();
    }
  }

  /// Clear all typing users
  void clearAll() {
    if (_typingUsers.isNotEmpty) {
      _typingUsers.clear();
      notifyListeners();
    }
  }

  /// Start cleanup timer to remove stale typing indicators
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _cleanupStaleUsers();
    });
  }

  /// Remove users who haven't typed recently
  void _cleanupStaleUsers() {
    final now = DateTime.now();
    final staleUsers = <String>[];

    for (final entry in _typingUsers.entries) {
      if (now.difference(entry.value.lastTypingTime) > _typingTimeout) {
        staleUsers.add(entry.key);
      }
    }

    if (staleUsers.isNotEmpty) {
      for (final userId in staleUsers) {
        _typingUsers.remove(userId);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
