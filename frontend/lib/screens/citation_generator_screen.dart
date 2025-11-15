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

class _CitationGeneratorScreenState extends State<CitationGeneratorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  
  // Manual citation controllers
  final _manualTitleController = TextEditingController();
  final _manualAuthorsController = TextEditingController();
  final _manualYearController = TextEditingController();
  final _manualJournalController = TextEditingController();
  final _manualVolumeController = TextEditingController();
  final _manualIssueController = TextEditingController();
  final _manualPagesController = TextEditingController();
  final _manualDoiController = TextEditingController();
  final _manualPublisherController = TextEditingController();
  final _manualIsbnController = TextEditingController();
  final _manualUrlController = TextEditingController();
  final _manualAccessDateController = TextEditingController();
  final _manualWebsiteNameController = TextEditingController();
  
  late TabController _tabController;
  String _selectedType = 'doi';
  String _manualSourceType = 'journal_article';
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

  final List<Map<String, String>> _sourceTypes = [
    {'value': 'journal_article', 'label': 'Journal Article'},
    {'value': 'book', 'label': 'Book'},
    {'value': 'website', 'label': 'Website'},
    {'value': 'conference_paper', 'label': 'Conference Paper'},
    {'value': 'thesis', 'label': 'Thesis/Dissertation'},
    {'value': 'report', 'label': 'Report'},
    {'value': 'newspaper', 'label': 'Newspaper Article'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _manualTitleController.dispose();
    _manualAuthorsController.dispose();
    _manualYearController.dispose();
    _manualJournalController.dispose();
    _manualVolumeController.dispose();
    _manualIssueController.dispose();
    _manualPagesController.dispose();
    _manualDoiController.dispose();
    _manualPublisherController.dispose();
    _manualIsbnController.dispose();
    _manualUrlController.dispose();
    _manualAccessDateController.dispose();
    _manualWebsiteNameController.dispose();
    _tabController.dispose();
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

  Future<void> _generateManualCitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _citation = null;
    });

    try {
      // Build metadata from manual input
      final metadata = PDFMetadata(
        title: _manualTitleController.text.trim().isNotEmpty
            ? _manualTitleController.text.trim()
            : null,
        authors: _manualAuthorsController.text.trim().isNotEmpty
            ? _manualAuthorsController.text
                .split(',')
                .map((a) => a.trim())
                .where((a) => a.isNotEmpty)
                .toList()
            : [],
        publicationYear: _manualYearController.text.trim().isNotEmpty
            ? int.tryParse(_manualYearController.text.trim())
            : null,
        journal: _manualJournalController.text.trim().isNotEmpty
            ? _manualJournalController.text.trim()
            : null,
        volume: _manualVolumeController.text.trim().isNotEmpty
            ? _manualVolumeController.text.trim()
            : null,
        issue: _manualIssueController.text.trim().isNotEmpty
            ? _manualIssueController.text.trim()
            : null,
        pages: _manualPagesController.text.trim().isNotEmpty
            ? _manualPagesController.text.trim()
            : null,
        doi: _manualDoiController.text.trim().isNotEmpty
            ? _manualDoiController.text.trim()
            : null,
        publisher: _manualPublisherController.text.trim().isNotEmpty
            ? _manualPublisherController.text.trim()
            : null,
        isbn: _manualIsbnController.text.trim().isNotEmpty
            ? _manualIsbnController.text.trim()
            : null,
        url: _manualUrlController.text.trim().isNotEmpty
            ? _manualUrlController.text.trim()
            : null,
      );

      final citation =
          await widget.metadataService.generateCitationFromMetadata(metadata);

      if (mounted) {
        setState(() {
          _citation = citation;
          _isLoading = false;
          if (citation == null) {
            _error = 'Could not generate citation. Please check your input.';
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

  void _clearManualForm() {
    _manualTitleController.clear();
    _manualAuthorsController.clear();
    _manualYearController.clear();
    _manualJournalController.clear();
    _manualVolumeController.clear();
    _manualIssueController.clear();
    _manualPagesController.clear();
    _manualDoiController.clear();
    _manualPublisherController.clear();
    _manualIsbnController.clear();
    _manualUrlController.clear();
    _manualAccessDateController.clear();
    _manualWebsiteNameController.clear();
    setState(() {
      _citation = null;
      _error = null;
    });
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Auto', icon: Icon(Icons.auto_awesome, size: 20)),
            Tab(text: 'Manual', icon: Icon(Icons.edit, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAutoTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildAutoTab() {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
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
                      Icons.edit,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manually enter citation details for any source type',
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

            // Source type dropdown
            DropdownButtonFormField<String>(
              value: _manualSourceType,
              decoration: const InputDecoration(
                labelText: 'Source Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _sourceTypes.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _manualSourceType = value!;
                  _clearManualForm();
                });
              },
            ),
            const SizedBox(height: 24),

            // Dynamic form fields based on source type
            ..._buildManualFormFields(),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearManualForm,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateManualCitation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                        _isLoading ? 'Generating...' : 'Generate Citations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
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

  List<Widget> _buildManualFormFields() {
    final fields = <Widget>[];

    // Common fields for all types
    fields.addAll([
      TextFormField(
        controller: _manualTitleController,
        decoration: const InputDecoration(
          labelText: 'Title *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.title),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Title is required';
          }
          return null;
        },
        maxLines: 2,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _manualAuthorsController,
        decoration: const InputDecoration(
          labelText: 'Authors/Editors *',
          hintText: 'Separate multiple authors with commas',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'At least one author is required';
          }
          return null;
        },
        maxLines: 2,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _manualYearController,
        decoration: const InputDecoration(
          labelText: 'Publication Year *',
          hintText: 'e.g., 2024',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Year is required';
          }
          final year = int.tryParse(value.trim());
          if (year == null || year < 1000 || year > DateTime.now().year + 1) {
            return 'Enter a valid year';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
    ]);

    // Type-specific fields
    switch (_manualSourceType) {
      case 'journal_article':
        fields.addAll([
          TextFormField(
            controller: _manualJournalController,
            decoration: const InputDecoration(
              labelText: 'Journal Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.book),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Journal name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _manualVolumeController,
                  decoration: const InputDecoration(
                    labelText: 'Volume',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _manualIssueController,
                  decoration: const InputDecoration(
                    labelText: 'Issue',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualPagesController,
            decoration: const InputDecoration(
              labelText: 'Pages',
              hintText: 'e.g., 123-145',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pages),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualDoiController,
            decoration: const InputDecoration(
              labelText: 'DOI (optional)',
              hintText: 'e.g., 10.1234/example',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]);
        break;

      case 'book':
        fields.addAll([
          TextFormField(
            controller: _manualPublisherController,
            decoration: const InputDecoration(
              labelText: 'Publisher *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Publisher is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualIsbnController,
            decoration: const InputDecoration(
              labelText: 'ISBN (optional)',
              hintText: 'e.g., 978-0-123456-78-9',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
        ]);
        break;

      case 'website':
        fields.addAll([
          TextFormField(
            controller: _manualWebsiteNameController,
            decoration: const InputDecoration(
              labelText: 'Website Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Website name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualUrlController,
            decoration: const InputDecoration(
              labelText: 'URL *',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'URL is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualAccessDateController,
            decoration: const InputDecoration(
              labelText: 'Access Date',
              hintText: 'e.g., January 15, 2024',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.event),
            ),
          ),
        ]);
        break;

      case 'conference_paper':
        fields.addAll([
          TextFormField(
            controller: _manualJournalController,
            decoration: const InputDecoration(
              labelText: 'Conference Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.event),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Conference name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualPagesController,
            decoration: const InputDecoration(
              labelText: 'Pages',
              hintText: 'e.g., 123-145',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pages),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualDoiController,
            decoration: const InputDecoration(
              labelText: 'DOI (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]);
        break;

      case 'thesis':
        fields.addAll([
          TextFormField(
            controller: _manualPublisherController,
            decoration: const InputDecoration(
              labelText: 'Institution *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Institution is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualUrlController,
            decoration: const InputDecoration(
              labelText: 'URL (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]);
        break;

      case 'report':
        fields.addAll([
          TextFormField(
            controller: _manualPublisherController,
            decoration: const InputDecoration(
              labelText: 'Institution/Organization *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Institution is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualUrlController,
            decoration: const InputDecoration(
              labelText: 'URL (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]);
        break;

      case 'newspaper':
        fields.addAll([
          TextFormField(
            controller: _manualJournalController,
            decoration: const InputDecoration(
              labelText: 'Newspaper Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.newspaper),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Newspaper name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualPagesController,
            decoration: const InputDecoration(
              labelText: 'Pages',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pages),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualUrlController,
            decoration: const InputDecoration(
              labelText: 'URL (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]);
        break;

      case 'other':
        fields.addAll([
          TextFormField(
            controller: _manualPublisherController,
            decoration: const InputDecoration(
              labelText: 'Publisher/Source',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualUrlController,
            decoration: const InputDecoration(
              labelText: 'URL (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ]);
        break;
    }

    return fields;
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
