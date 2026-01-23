import 'package:flutter/material.dart';

/// Draggable resize handle for panels
class WorkspaceResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final bool isVertical;

  const WorkspaceResizeHandle({
    super.key,
    required this.onDrag,
    this.isVertical = true,
  });

  @override
  State<WorkspaceResizeHandle> createState() => _WorkspaceResizeHandleState();
}

class _WorkspaceResizeHandleState extends State<WorkspaceResizeHandle> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isVertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onHorizontalDragStart: widget.isVertical
            ? (_) => setState(() => _isDragging = true)
            : null,
        onHorizontalDragUpdate: widget.isVertical
            ? (details) => widget.onDrag(details.delta.dx)
            : null,
        onHorizontalDragEnd: widget.isVertical
            ? (_) => setState(() => _isDragging = false)
            : null,
        onVerticalDragStart: !widget.isVertical
            ? (_) => setState(() => _isDragging = true)
            : null,
        onVerticalDragUpdate: !widget.isVertical
            ? (details) => widget.onDrag(details.delta.dy)
            : null,
        onVerticalDragEnd: !widget.isVertical
            ? (_) => setState(() => _isDragging = false)
            : null,
        child: Container(
          width: widget.isVertical ? 8 : null,
          height: !widget.isVertical ? 8 : null,
          decoration: BoxDecoration(
            gradient: _isDragging
                ? LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.6),
                      Colors.purple.withValues(alpha: 0.6),
                    ],
                    begin: widget.isVertical
                        ? Alignment.topCenter
                        : Alignment.centerLeft,
                    end: widget.isVertical
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                  )
                : null,
            color: _isDragging ? null : Colors.transparent,
          ),
          child: Center(
            child: Container(
              width: widget.isVertical ? 3 : null,
              height: !widget.isVertical ? 3 : null,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
