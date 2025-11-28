import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/drive_service.dart';
import '../services/cache_service.dart';

class PdfThumbnail extends StatefulWidget {
  final DriveFile file;
  final double width;
  final double height;
  final BoxFit fit;

  const PdfThumbnail({
    super.key,
    required this.file,
    this.width = 120,
    this.height = 160,
    this.fit = BoxFit.cover,
  });

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  Uint8List? _thumbnailBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    if (!widget.file.isPdf) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final cacheService = context.read<CacheService>();
      final driveService = context.read<DriveService>();

      final cachedThumbnail =
          await cacheService.getPdfThumbnail(widget.file.id);

      if (cachedThumbnail != null && mounted) {
        setState(() {
          _thumbnailBytes = cachedThumbnail;
          _isLoading = false;
        });
        return;
      }

      final pdfBytes = await driveService.downloadFile(widget.file.id);

      if (pdfBytes == null || pdfBytes.isEmpty) {
        throw Exception('Failed to download PDF');
      }

      final document = await PdfDocument.openData(pdfBytes);

      if (document.pagesCount == 0) {
        await document.close();
        throw Exception('PDF has no pages');
      }

      final page = await document.getPage(1);

      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      if (pageImage == null) {
        await page.close();
        await document.close();
        throw Exception('Failed to render page');
      }

      final thumbnailBytes = pageImage.bytes;

      await page.close();
      await document.close();

      await cacheService.cachePdfThumbnail(widget.file.id, thumbnailBytes);

      if (mounted) {
        setState(() {
          _thumbnailBytes = thumbnailBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        ),
      );
    }

    if (_hasError || _thumbnailBytes == null) {
      return _buildFallbackIcon();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _thumbnailBytes!,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 48,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
