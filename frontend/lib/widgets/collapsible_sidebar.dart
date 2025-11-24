import 'package:flutter/material.dart';

/// A collapsible sidebar with a handle bar for expanding/collapsing
class CollapsibleSidebar extends StatefulWidget {
  final Widget child;
  final double width;
  final bool initiallyExpanded;
  final VoidCallback? onClose;
  final String title;

  const CollapsibleSidebar({
    super.key,
    required this.child,
    required this.width,
    this.initiallyExpanded = true,
    this.onClose,
    required this.title,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: _isExpanded ? widget.width : 40,
      end: _isExpanded ? widget.width : 40,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _widthAnimation = Tween<double>(
        begin: _isExpanded ? 40 : widget.width,
        end: _isExpanded ? widget.width : 40,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return SizedBox(
          width: _widthAnimation.value,
          child: Row(
            children: [
              // Handle bar
              GestureDetector(
                onTap: _toggleExpanded,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE0E0E0),
                      border: Border(
                        left: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Vertical text (rotated)
                        if (!_isExpanded)
                          Expanded(
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Toggle icon
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Icon(
                            _isExpanded
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                            size: 20,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              if (_isExpanded)
                Expanded(
                  child: widget.child,
                ),
            ],
          ),
        );
      },
    );
  }
}
