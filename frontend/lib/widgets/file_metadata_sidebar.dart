import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pdf_metadata.dart';
import '../models/drive_file.dart';
import '../services/metadata_service.dart';

class FileMetadataSidebar extends StatefulWidget {
  final DriveFile file;
  final MetadataService metadataService;
  final VoidCallback? onClose;

  const FileMetadataSidebar({
    super.key,
    required this.file,
    required this.metadataService,
    this.onClose,
  });

  @override
  State<FileMetadataSidebar> createState() => _FileMetadataSidebarState();
}

class _FileMetadataSidebarState extends State<FileMetadataSidebar> {
  PDFMetadata? _metadata;
  bool _isLoading = false;
  String? _error;
  Citation? _citations;
  bool _isGeneratingCitations = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    if (!widget.file.isPdf) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final metadata = await widget.metadataService.extractMetadata(
        fileId: widget.file.id,
        fileName: widget.file.name,
        extractFromContent: true,
      );

      if (mounted) {
        setState(() {
          _metadata = metadata;
          _isLoading = false;
        });
        // Auto-generate citations if metadata is available
        if (metadata != null) {
          _generateCitations();
        }
      }
    } catch (e) {
      print('Error loading metadata: $e');
      if (mounted) {
        String errorMessage = 'Failed to load metadata';

        // Provide more specific error messages
        if (e.toString().contains('timed out')) {
          errorMessage = 'Request timed out. Backend may not be running.';
        } else if (e.toString().contains('not authenticated') ||
            e.toString().contains('Authentication failed')) {
          errorMessage = 'Authentication error. Please sign in again.';
        } else if (e.toString().contains('not found')) {
          errorMessage = 'File not found in Google Drive';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          errorMessage = 'Cannot connect to backend. Is it running?';
        } else {
          errorMessage =
              'Failed to load metadata: ${e.toString().replaceAll('Exception: ', '')}';
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateCitations() async {
    if (_metadata == null) return;

    setState(() {
      _isGeneratingCitations = true;
    });

    try {
      final citations = await widget.metadataService
          .generateCitationFromMetadata(_metadata!);

      if (mounted) {
        setState(() {
          _citations = citations;
          _isGeneratingCitations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingCitations = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'File Metadata',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    tooltip: 'Close',
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadMetadata,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildMetadataContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataContent() {
    if (!widget.file.isPdf) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Metadata extraction is only available for PDF files',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show basic file info even if metadata extraction failed
    if (_metadata == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No embedded metadata found in this PDF',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('File Information'),
            _buildInfoRow('File Name', widget.file.name),
            if (widget.file.size != null)
              _buildInfoRow('File Size', widget.file.formattedSize),
            if (widget.file.createdTime != null)
              _buildInfoRow('Created', _formatDate(widget.file.createdTime!)),
            if (widget.file.modifiedTime != null)
              _buildInfoRow('Modified', _formatDate(widget.file.modifiedTime!)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (_metadata!.title != null) ...[
            _buildSectionHeader('Title'),
            _buildCopyableField(_metadata!.title!, 'Title'),
            const SizedBox(height: 16),
          ],

          // Authors
          if (_metadata!.authors.isNotEmpty) ...[
            _buildSectionHeader('Authors'),
            ..._metadata!.authors.map(
              (author) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildCopyableField(author, 'Author'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Publication Year
          if (_metadata!.publicationYear != null) ...[
            _buildSectionHeader('Publication Year'),
            _buildCopyableField(_metadata!.publicationYear.toString(), 'Year'),
            const SizedBox(height: 16),
          ],

          // Journal
          if (_metadata!.journal != null) ...[
            _buildSectionHeader('Journal'),
            _buildCopyableField(_metadata!.journal!, 'Journal'),
            const SizedBox(height: 16),
          ],

          // Conference
          if (_metadata!.conference != null) ...[
            _buildSectionHeader('Conference'),
            _buildCopyableField(_metadata!.conference!, 'Conference'),
            const SizedBox(height: 16),
          ],

          // DOI
          if (_metadata!.doi != null) ...[
            _buildSectionHeader('DOI'),
            _buildLinkField(
              _metadata!.doi!,
              'https://doi.org/${_metadata!.doi}',
              'DOI',
            ),
            const SizedBox(height: 16),
          ],

          // ISBN
          if (_metadata!.isbn != null) ...[
            _buildSectionHeader('ISBN'),
            _buildCopyableField(_metadata!.isbn!, 'ISBN'),
            const SizedBox(height: 16),
          ],

          // PMID
          if (_metadata!.pmid != null) ...[
            _buildSectionHeader('PubMed ID'),
            _buildLinkField(
              _metadata!.pmid!,
              'https://pubmed.ncbi.nlm.nih.gov/${_metadata!.pmid}/',
              'PMID',
            ),
            const SizedBox(height: 16),
          ],

          // arXiv ID
          if (_metadata!.arxivId != null) ...[
            _buildSectionHeader('arXiv ID'),
            _buildLinkField(
              _metadata!.arxivId!,
              'https://arxiv.org/abs/${_metadata!.arxivId}',
              'arXiv ID',
            ),
            const SizedBox(height: 16),
          ],

          // Volume, Issue, Pages
          if (_metadata!.volume != null ||
              _metadata!.issue != null ||
              _metadata!.pages != null) ...[
            _buildSectionHeader('Publication Details'),
            if (_metadata!.volume != null)
              _buildInfoRow('Volume', _metadata!.volume!),
            if (_metadata!.issue != null)
              _buildInfoRow('Issue', _metadata!.issue!),
            if (_metadata!.pages != null)
              _buildInfoRow('Pages', _metadata!.pages!),
            const SizedBox(height: 16),
          ],

          // Publisher
          if (_metadata!.publisher != null) ...[
            _buildSectionHeader('Publisher'),
            _buildCopyableField(_metadata!.publisher!, 'Publisher'),
            const SizedBox(height: 16),
          ],

          // Abstract
          if (_metadata!.abstract != null) ...[
            _buildSectionHeader('Abstract'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _metadata!.abstract!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          _copyToClipboard(_metadata!.abstract!, 'Abstract'),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Keywords
          if (_metadata!.keywords.isNotEmpty) ...[
            _buildSectionHeader('Keywords'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _metadata!.keywords
                  .map(
                    (keyword) => Chip(
                      label: Text(keyword),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Citations Section
          const Divider(height: 32),
          _buildSectionHeader('Generated Citations'),
          if (_isGeneratingCitations)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_citations != null) ...[
            _buildCitationCard('APA', _citations!.apa),
            const SizedBox(height: 12),
            _buildCitationCard('MLA', _citations!.mla),
            const SizedBox(height: 12),
            _buildCitationCard('Chicago', _citations!.chicago),
            const SizedBox(height: 12),
            _buildCitationCard('BibTeX', _citations!.bibtex),
            const SizedBox(height: 16),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Citations will be generated from metadata',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // File Information
          _buildSectionHeader('File Information'),
          _buildInfoRow('File Name', widget.file.name),
          if (widget.file.size != null)
            _buildInfoRow('File Size', widget.file.formattedSize),
          if (widget.file.createdTime != null)
            _buildInfoRow('Created', _formatDate(widget.file.createdTime!)),
          if (widget.file.modifiedTime != null)
            _buildInfoRow('Modified', _formatDate(widget.file.modifiedTime!)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCopyableField(String text, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyToClipboard(text, label),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }

  Widget _buildLinkField(String text, String url, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                // TODO: Open URL in browser
                _copyToClipboard(url, label);
              },
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyToClipboard(url, label),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildCitationCard(String format, String citation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                format,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyToClipboard(citation, '$format citation'),
                tooltip: 'Copy $format citation',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(citation, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
