import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/extracted_document.dart';
import '../services/document_extraction_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/glass_container.dart';
import 'extracted_document_detail_screen.dart';

/// Screen to display all extracted documents
class ExtractedDocumentsScreen extends StatefulWidget {
  const ExtractedDocumentsScreen({super.key});

  @override
  State<ExtractedDocumentsScreen> createState() =>
      _ExtractedDocumentsScreenState();
}

class _ExtractedDocumentsScreenState extends State<ExtractedDocumentsScreen> {
  List<ExtractedDocument> _documents = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<DocumentExtractionService>();
      final documents = await service.getExtractedDocuments();
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<DocumentExtractionService>();
      final documents = await service.searchDocuments(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        documentType: _selectedType,
      );
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByType(String? type) {
    setState(() {
      _selectedType = type;
    });
    _searchDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleTextColor = textColor.withValues(alpha: 0.7);
    final verySubtleTextColor = textColor.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Extracted Documents', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      hintStyle: TextStyle(color: subtleTextColor),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: subtleTextColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: subtleTextColor),
                              onPressed: () {
                                _searchController.clear();
                                _searchDocuments();
                              },
                            )
                          : null,
                    ),
                    style: TextStyle(color: textColor),
                    onSubmitted: (_) => _searchDocuments(),
                  ),
                ),
                const SizedBox(height: 12),
                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null, textColor, subtleTextColor),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Hospital',
                        'Hospital',
                        textColor,
                        subtleTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Appointment',
                        'Appointment',
                        textColor,
                        subtleTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'ID Card',
                        'ID Card',
                        textColor,
                        subtleTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Bill',
                        'Bill',
                        textColor,
                        subtleTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Prescription',
                        'Prescription',
                        textColor,
                        subtleTextColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Receipt',
                        'Receipt',
                        textColor,
                        subtleTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Documents List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDocuments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _documents.isEmpty
                ? _buildEmptyState(textColor, verySubtleTextColor)
                : _buildDocumentsList(
                    textColor,
                    subtleTextColor,
                    verySubtleTextColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? type,
    Color textColor,
    Color subtleTextColor,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => _filterByType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : textColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : textColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : subtleTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color verySubtleTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 100,
            color: textColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No extracted documents',
            style: TextStyle(fontSize: 18, color: verySubtleTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a document to get started',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(
    Color textColor,
    Color subtleTextColor,
    Color verySubtleTextColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDocumentCard(
            document,
            textColor,
            subtleTextColor,
            verySubtleTextColor,
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(
    ExtractedDocument document,
    Color textColor,
    Color subtleTextColor,
    Color verySubtleTextColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ExtractedDocumentDetailScreen(document: document),
          ),
        ).then((_) => _loadDocuments());
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  document.typeIcon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Document Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      document.documentType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Summary
                  Text(
                    document.summary,
                    style: TextStyle(color: textColor, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  if (document.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: document.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: textColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: subtleTextColor,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  // Date
                  Text(
                    document.formattedDate,
                    style: TextStyle(color: verySubtleTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(Icons.chevron_right, color: verySubtleTextColor),
          ],
        ),
      ),
    );
  }
}
