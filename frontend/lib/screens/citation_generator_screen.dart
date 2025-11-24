import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pdf_metadata.dart';
import '../services/metadata_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/ui/modern_text_field.dart';
import '../theme/app_colors.dart';

class CitationGeneratorScreen extends StatefulWidget {
  final MetadataService? metadataService;

  const CitationGeneratorScreen({super.key, this.metadataService});

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
      final metadataService =
          widget.metadataService ?? context.read<MetadataService>();
      final citation = await metadataService.generateCitation(
        identifierType: _selectedType,
        identifierValue: _identifierController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _citation = citation;
          _isLoading = false;
          if (citation == null) {
            _error =
                'Could not generate citation. Please check the identifier.';
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

      final metadataService =
          widget.metadataService ?? context.read<MetadataService>();
      final citation = await metadataService.generateCitationFromMetadata(
        metadata,
      );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Citation Generator'),
        backgroundColor: isDark ? AppColors.surface : null,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondary : Colors.grey,
          tabs: const [
            Tab(text: 'Auto', icon: Icon(Icons.auto_awesome, size: 20)),
            Tab(text: 'Manual', icon: Icon(Icons.edit, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAutoTab(), _buildManualTab()],
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
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Generate formatted citations from DOI, ISBN, PubMed ID, arXiv ID, or URL',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      dropdownColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppColors.surface
                          : null,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  ),
                ),
                const SizedBox(height: 16),

                // Identifier input
                ModernTextField(
                  controller: _identifierController,
                  hintText:
                      '${_identifierTypes.firstWhere((t) => t['value'] == _selectedType)['label']} (${_identifierTypes.firstWhere((t) => t['value'] == _selectedType)['hint']})',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an identifier';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _generateCitation(),
                ),
                const SizedBox(height: 24),

                // Generate button
                ModernButton(
                  onPressed: _isLoading ? () {} : _generateCitation,
                  icon: _isLoading ? null : Icons.auto_awesome,
                  label: _isLoading ? 'Generating...' : 'Generate Citations',
                  width: double.infinity,
                  height: 50,
                ),
              ],
            ),
          ),

          // Error message
          if (_error != null) ...[
            const SizedBox(height: 24),
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              color: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata preview
            if (_citation!.metadata != null) ...[
              _buildMetadataPreview(_citation!.metadata!),
              const SizedBox(height: 24),
            ],

            // APA
            _buildCitationCard('APA', _citation!.apa, Icons.format_quote),
            const SizedBox(height: 16),

            // MLA
            _buildCitationCard('MLA', _citation!.mla, Icons.format_quote),
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
            GlassContainer(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manually enter citation details for any source type',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Source type dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _manualSourceType,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surface
                      : null,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
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
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic form fields based on source type
            ..._buildManualFormFields(),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    onPressed: _clearManualForm,
                    icon: Icons.clear,
                    label: 'Clear',
                    backgroundColor: Colors.transparent,
                    textColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ModernButton(
                    onPressed: _isLoading ? () {} : _generateManualCitation,
                    icon: _isLoading ? null : Icons.auto_awesome,
                    label: _isLoading ? 'Generating...' : 'Generate Citations',
                  ),
                ),
              ],
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 24),
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                color: Colors.red.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // APA
              _buildCitationCard('APA', _citation!.apa, Icons.format_quote),
              const SizedBox(height: 16),

              // MLA
              _buildCitationCard('MLA', _citation!.mla, Icons.format_quote),
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
      ModernTextField(
        controller: _manualTitleController,
        hintText: 'Title *',
        prefixIcon: Icons.title,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Title is required';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      ModernTextField(
        controller: _manualAuthorsController,
        hintText: 'Authors/Editors * (Separate with commas)',
        prefixIcon: Icons.person,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'At least one author is required';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      ModernTextField(
        controller: _manualYearController,
        hintText: 'Publication Year * (e.g., 2024)',
        prefixIcon: Icons.calendar_today,
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
          ModernTextField(
            controller: _manualJournalController,
            hintText: 'Journal Name *',
            prefixIcon: Icons.book,
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
                child: ModernTextField(
                  controller: _manualVolumeController,
                  hintText: 'Volume',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernTextField(
                  controller: _manualIssueController,
                  hintText: 'Issue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualPagesController,
            hintText: 'Pages (e.g., 123-145)',
            prefixIcon: Icons.pages,
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualDoiController,
            hintText: 'DOI (optional)',
            prefixIcon: Icons.link,
          ),
        ]);
        break;

      case 'book':
        fields.addAll([
          ModernTextField(
            controller: _manualPublisherController,
            hintText: 'Publisher *',
            prefixIcon: Icons.business,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Publisher is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualIsbnController,
            hintText: 'ISBN (optional)',
            prefixIcon: Icons.numbers,
          ),
        ]);
        break;

      case 'website':
        fields.addAll([
          ModernTextField(
            controller: _manualWebsiteNameController,
            hintText: 'Website Name *',
            prefixIcon: Icons.language,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Website name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualUrlController,
            hintText: 'URL *',
            prefixIcon: Icons.link,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'URL is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualAccessDateController,
            hintText: 'Access Date (e.g., January 15, 2024)',
            prefixIcon: Icons.event,
          ),
        ]);
        break;

      case 'conference_paper':
        fields.addAll([
          ModernTextField(
            controller: _manualJournalController,
            hintText: 'Conference Name *',
            prefixIcon: Icons.event,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Conference name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualPublisherController,
            hintText: 'Publisher',
            prefixIcon: Icons.business,
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualPagesController,
            hintText: 'Pages',
            prefixIcon: Icons.pages,
          ),
        ]);
        break;

      default:
        fields.addAll([
          ModernTextField(
            controller: _manualPublisherController,
            hintText: 'Publisher/Institution',
            prefixIcon: Icons.business,
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _manualUrlController,
            hintText: 'URL (optional)',
            prefixIcon: Icons.link,
          ),
        ]);
    }

    return fields;
  }

  Widget _buildMetadataPreview(PDFMetadata metadata) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Source Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metadata.title != null) ...[
            Text(
              metadata.title!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (metadata.authors.isNotEmpty) ...[
            Text(
              metadata.authors.join(', '),
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (metadata.journal != null || metadata.publicationYear != null) ...[
            Text(
              [
                if (metadata.journal != null) metadata.journal,
                if (metadata.publicationYear != null)
                  metadata.publicationYear.toString(),
              ].join(' • '),
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitationCard(
    String format,
    String text,
    IconData icon, {
    bool monospace = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: isDark ? AppColors.surface : Colors.white.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    format,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.copy,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () => _copyToClipboard(text, format),
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SelectableText(
              text,
              style: TextStyle(
                fontFamily: monospace ? 'Courier New' : null,
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
