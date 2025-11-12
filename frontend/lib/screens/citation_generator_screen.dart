import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pdf_metadata.dart';
import '../services/metadata_service.dart';

class CitationGeneratorScreen extends StatefulWidget {
  final MetadataService metadataService;

  const CitationGeneratorScreen({
    Key? key,
    required this.metadataService,
  }) : super(key: key);

  @override
  State<CitationGeneratorScreen> createState() =>
      _CitationGeneratorScreenState();
}

class _CitationGeneratorScreenState extends State<CitationGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  
  String _selectedType = 'doi';
  Citation? _citation;
  bool _isLoading = false;
  String? _error;

  final List<Map<String, String>> _identifierTypes = [
    {'value': 'doi', 'label': 'DOI', 'hint': 'e.g., 10.1234/example'},
    {'value': 'arxiv', 'label': 'arXiv ID', 'hint': 'e.g., 2301.12345'},
    {'value': 'isbn', 'label': 'ISBN', 'hint': 'e.g., 978-0-123456-78-9'},
    {'value': 'pmid', 'label': 'PubMed ID', 'hint': 'e.g., 12345678'},
    {'value': 'url', 'label': 'URL', 'hint': 'URL containing DOI or arXiv ID'},
  ];

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _generateCitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _citation = null;
    });

    try {
      final citation = await widget.metadataService.generateCitation(
        identifierType: _selectedType,
        identifierValue: _identifierController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _citation = citation;
          _isLoading = false;
          if (citation == null) {
            _error = 'Could not generate citation. Please check the identifier.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String format) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$format citation copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citation Generator'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Generate formatted citations from DOI, ISBN, PubMed ID, arXiv ID, or URL',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identifier type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Identifier Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _identifierTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _identifierController.clear();
                        _citation = null;
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Identifier input
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: _identifierTypes
                          .firstWhere((t) => t['value'] == _selectedType)['label'],
                      hintText: _identifierTypes
                          .firstWhere((t) => t['value'] == _selectedType)['hint'],
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an identifier';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _generateCitation(),
                  ),
                  const SizedBox(height: 24),

                  // Generate button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateCitation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isLoading ? 'Generating...' : 'Generate Citations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Citations display
            if (_citation != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Generated Citations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Metadata preview
              if (_citation!.metadata != null) ...[
                _buildMetadataPreview(_citation!.metadata!),
                const SizedBox(height: 24),
              ],

              // APA
              _buildCitationCard(
                'APA',
                _citation!.apa,
                Icons.format_quote,
              ),
              const SizedBox(height: 16),

              // MLA
              _buildCitationCard(
                'MLA',
                _citation!.mla,
                Icons.format_quote,
              ),
              const SizedBox(height: 16),

              // Chicago
              _buildCitationCard(
                'Chicago',
                _citation!.chicago,
                Icons.format_quote,
              ),
              const SizedBox(height: 16),

              // BibTeX
              _buildCitationCard(
                'BibTeX',
                _citation!.bibtex,
                Icons.code,
                monospace: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataPreview(PDFMetadata metadata) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Source Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (metadata.title != null) ...[
              _buildMetadataRow('Title', metadata.title!),
              const SizedBox(height: 8),
            ],
            if (metadata.authors.isNotEmpty) ...[
              _buildMetadataRow('Authors', metadata.formattedAuthors),
              const SizedBox(height: 8),
            ],
            if (metadata.publicationYear != null) ...[
              _buildMetadataRow('Year', metadata.publicationYear.toString()),
              const SizedBox(height: 8),
            ],
            if (metadata.journal != null) ...[
              _buildMetadataRow('Journal', metadata.journal!),
              const SizedBox(height: 8),
            ],
            if (metadata.doi != null) ...[
              _buildMetadataRow('DOI', metadata.doi!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildCitationCard(
    String format,
    String citation,
    IconData icon, {
    bool monospace = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  format,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(citation, format),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: SelectableText(
                citation,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: monospace ? 'monospace' : null,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
