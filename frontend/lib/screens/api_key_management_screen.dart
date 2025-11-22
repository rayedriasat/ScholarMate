import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_key.dart';
import '../services/api_key_service.dart';

class ApiKeyManagementScreen extends StatefulWidget {
  final String userId;
  final String baseUrl;

  const ApiKeyManagementScreen({
    super.key,
    required this.userId,
    required this.baseUrl,
  });

  @override
  State<ApiKeyManagementScreen> createState() => _ApiKeyManagementScreenState();
}

class _ApiKeyManagementScreenState extends State<ApiKeyManagementScreen> {
  late ApiKeyService _apiKeyService;
  List<ApiKeyModel> _keys = [];
  List<ProviderConfig> _providers = [];
  List<UsageStats> _stats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiKeyService = ApiKeyService(
      baseUrl: widget.baseUrl,
      userId: widget.userId,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final keys = await _apiKeyService.getUserKeys();
      final providers = await _apiKeyService.getProviders();
      final stats = await _apiKeyService.getUsageStats(days: 30);

      setState(() {
        _keys = keys;
        _providers = providers;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showAddKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AddApiKeyDialog(
        providers: _providers,
        apiKeyService: _apiKeyService,
        onKeyAdded: _loadData,
      ),
    );
  }

  void _showEditKeyDialog(ApiKeyModel key) {
    showDialog(
      context: context,
      builder: (context) => EditApiKeyDialog(
        apiKey: key,
        apiKeyService: _apiKeyService,
        onKeyUpdated: _loadData,
      ),
    );
  }

  Future<void> _deleteKey(ApiKeyModel key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key'),
        content: Text(
          'Are you sure you want to delete the ${key.provider} key?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiKeyService.deleteKey(key.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('API key deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _toggleKeyActive(ApiKeyModel key) async {
    try {
      await _apiKeyService.updateKey(keyId: key.id, isActive: !key.isActive);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Key Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Usage Stats Section
                  if (_stats.isNotEmpty) ...[
                    _buildUsageStatsSection(),
                    const SizedBox(height: 24),
                  ],

                  // API Keys Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your API Keys',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      FilledButton.icon(
                        onPressed: _showAddKeyDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Key'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_keys.isEmpty)
                    _buildEmptyState()
                  else
                    ..._keys.map((key) => _buildKeyCard(key)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddKeyDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUsageStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Statistics (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        stat.provider.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${stat.totalRequests} requests'),
                          Text('${stat.totalTokens} tokens'),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${stat.totalCost.toStringAsFixed(4)}'),
                          Text(
                            '${stat.successRate.toStringAsFixed(1)}% success',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.key_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No API Keys', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Add your first API key to start using custom AI providers',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showAddKeyDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add API Key'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyCard(ApiKeyModel key) {
    final provider = _providers.firstWhere(
      (p) => p.name == key.provider,
      orElse: () => ProviderConfig(
        name: key.provider,
        displayName: key.provider.toUpperCase(),
        supportsChat: true,
        supportsEmbeddings: false,
        apiKeyFormat: '',
        docsUrl: '',
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: key.isActive ? Colors.green : Colors.grey,
          child: Text(
            provider.displayName[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(provider.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Key: ${key.maskedKey}'),
            Row(
              children: [
                Icon(
                  key.isValidated ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: key.isValidated ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  key.isValidated ? 'Validated' : 'Not validated',
                  style: TextStyle(
                    color: key.isValidated ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Text('Priority: ${key.priority}'),
              ],
            ),
            if (key.validationError != null)
              Text(
                'Error: ${key.validationError}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(key.isActive ? Icons.pause : Icons.play_arrow),
                title: Text(key.isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _toggleKeyActive(key),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _showEditKeyDialog(key),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _deleteKey(key),
            ),
          ],
        ),
      ),
    );
  }
}

// Add API Key Dialog
class AddApiKeyDialog extends StatefulWidget {
  final List<ProviderConfig> providers;
  final ApiKeyService apiKeyService;
  final VoidCallback onKeyAdded;

  const AddApiKeyDialog({
    super.key,
    required this.providers,
    required this.apiKeyService,
    required this.onKeyAdded,
  });

  @override
  State<AddApiKeyDialog> createState() => _AddApiKeyDialogState();
}

class _AddApiKeyDialogState extends State<AddApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  ProviderConfig? _selectedProvider;
  int _priority = 0;
  bool _validate = true;
  bool _saving = false;
  bool _obscureKey = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    if (!_formKey.currentState!.validate() || _selectedProvider == null) {
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.apiKeyService.saveKey(
        provider: _selectedProvider!.name,
        apiKey: _keyController.text.trim(),
        priority: _priority,
        validate: _validate,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onKeyAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved successfully')),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add API Key'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Selection
              DropdownButtonFormField<ProviderConfig>(
                initialValue: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                ),
                items: widget.providers.map((provider) {
                  return DropdownMenuItem(
                    value: provider,
                    child: Text(provider.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedProvider = value),
                validator: (value) =>
                    value == null ? 'Please select a provider' : null,
              ),

              if (_selectedProvider != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Format: ${_selectedProvider!.apiKeyFormat}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () async {
                    // Open docs URL
                    final url = _selectedProvider!.docsUrl;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Docs: $url')));
                  },
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('How to get API key'),
                ),
              ],

              const SizedBox(height: 16),

              // API Key Input
              TextFormField(
                controller: _keyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                obscureText: _obscureKey,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an API key';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Priority
              TextFormField(
                initialValue: _priority.toString(),
                decoration: const InputDecoration(
                  labelText: 'Priority (higher = preferred)',
                  border: OutlineInputBorder(),
                  helperText: '0-100, higher values are preferred',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _priority = int.tryParse(value) ?? 0,
              ),

              const SizedBox(height: 16),

              // Validate checkbox
              CheckboxListTile(
                value: _validate,
                onChanged: (value) => setState(() => _validate = value ?? true),
                title: const Text('Validate key before saving'),
                subtitle: const Text(
                  'Test the key with a lightweight API call',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _saveKey,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// Edit API Key Dialog
class EditApiKeyDialog extends StatefulWidget {
  final ApiKeyModel apiKey;
  final ApiKeyService apiKeyService;
  final VoidCallback onKeyUpdated;

  const EditApiKeyDialog({
    super.key,
    required this.apiKey,
    required this.apiKeyService,
    required this.onKeyUpdated,
  });

  @override
  State<EditApiKeyDialog> createState() => _EditApiKeyDialogState();
}

class _EditApiKeyDialogState extends State<EditApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _priority;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priority = widget.apiKey.priority;
  }

  Future<void> _updateKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.apiKeyService.updateKey(
        keyId: widget.apiKey.id,
        priority: _priority,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onKeyUpdated();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('API key updated')));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.apiKey.provider.toUpperCase()} Key'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _priority.toString(),
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                helperText: 'Higher values are preferred (0-100)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _priority = int.tryParse(value) ?? 0,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _updateKey,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
