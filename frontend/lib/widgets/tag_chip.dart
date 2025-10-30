import 'package:flutter/material.dart';
import '../models/tag.dart';

/// Widget for displaying a tag as a colored chip
class TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool small;

  const TagChip({
    super.key,
    required this.tag,
    this.onTap,
    this.onDelete,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = _parseColor(tag.color);
    final textColor = _getContrastColor(chipColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8,
          vertical: small ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label, size: small ? 12 : 14, color: textColor),
            SizedBox(width: small ? 2 : 4),
            Text(
              tag.name,
              style: TextStyle(
                color: textColor,
                fontSize: small ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              SizedBox(width: small ? 2 : 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: small ? 12 : 14,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;

    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Widget for displaying multiple tags in a wrap
class TagChipList extends StatelessWidget {
  final List<Tag> tags;
  final Function(Tag)? onTagTap;
  final Function(Tag)? onTagDelete;
  final bool small;
  final int? maxTags;

  const TagChipList({
    super.key,
    required this.tags,
    this.onTagTap,
    this.onTagDelete,
    this.small = false,
    this.maxTags,
  });

  @override
  Widget build(BuildContext context) {
    final displayTags = maxTags != null && tags.length > maxTags!
        ? tags.take(maxTags!).toList()
        : tags;

    final remainingCount = maxTags != null && tags.length > maxTags!
        ? tags.length - maxTags!
        : 0;

    return Wrap(
      spacing: small ? 4 : 6,
      runSpacing: small ? 4 : 6,
      children: [
        ...displayTags.map(
          (tag) => TagChip(
            tag: tag,
            onTap: onTagTap != null ? () => onTagTap!(tag) : null,
            onDelete: onTagDelete != null ? () => onTagDelete!(tag) : null,
            small: small,
          ),
        ),
        if (remainingCount > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 6 : 8,
              vertical: small ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: small ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
      ],
    );
  }
}
