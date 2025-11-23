import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_key.dart';
import '../services/api_key_service.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/ui/modern_text_field.dart';
import '../theme/app_colors.dart';

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
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete API Key',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete the ${key.provider} key?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ModernButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Delete',
            backgroundColor: Colors.red,
            width: 80,
            height: 36,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'API Key Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ModernButton(onPressed: _loadData, label: 'Retry'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
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
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      ModernButton(
                        onPressed: _showAddKeyDialog,
                        icon: Icons.add,
                        label: 'Add Key',
                        width: 120,
                        height: 36,
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
    );
  }

  Widget _buildUsageStatsSection() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Statistics (Last 30 Days)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stat.totalRequests} requests',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${stat.totalTokens} tokens',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${stat.totalCost.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${stat.successRate.toStringAsFixed(1)}% success',
                          style: TextStyle(
                            color: stat.successRate > 90
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 12,
                          ),
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
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.key_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No API Keys',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first API key to start using custom AI providers',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ModernButton(
            onPressed: _showAddKeyDialog,
            icon: Icons.add,
            label: 'Add API Key',
          ),
        ],
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

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: key.isActive
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          child: Text(
            provider.displayName[0],
            style: TextStyle(color: key.isActive ? Colors.green : Colors.grey),
          ),
        ),
        title: Text(
          provider.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Key: ${key.maskedKey}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Priority: ${key.priority}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (key.validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Error: ${key.validationError}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppColors.surface,
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  key.isActive ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                title: Text(
                  key.isActive ? 'Deactivate' : 'Activate',
                  style: const TextStyle(color: Colors.white),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _toggleKeyActive(key),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.edit, color: Colors.white),
                title: Text('Edit', style: TextStyle(color: Colors.white)),
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
      backgroundColor: AppColors.surface,
      title: const Text('Add API Key', style: TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Selection
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
                  child: DropdownButtonFormField<ProviderConfig>(
                    value: _selectedProvider,
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: widget.providers.map((provider) {
                      return DropdownMenuItem(
                        value: provider,
                        child: Text(provider.displayName),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedProvider = value),
                    validator: (value) =>
                        value == null ? 'Please select a provider' : null,
                  ),
                ),
              ),

              if (_selectedProvider != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Format: ${_selectedProvider!.apiKeyFormat}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              ModernTextField(
                controller: _keyController,
                hintText: 'API Key',
                obscureText: _obscureKey,
                suffixIcon: _obscureKey
                    ? Icons.visibility
                    : Icons.visibility_off,
                onSuffixIconPressed: () =>
                    setState(() => _obscureKey = !_obscureKey),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an API key';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Priority
              ModernTextField(
                initialValue: _priority.toString(),
                hintText: 'Priority (0-100)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _priority = int.tryParse(value) ?? 0,
              ),

              const SizedBox(height: 16),

              // Validate checkbox
              CheckboxListTile(
                value: _validate,
                onChanged: (value) => setState(() => _validate = value ?? true),
                title: const Text(
                  'Validate key before saving',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Test the key with a lightweight API call',
                  style: TextStyle(color: Colors.white70),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                checkColor: Colors.white,
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
        ModernButton(
          onPressed: _saving ? () {} : _saveKey,
          label: _saving ? 'Saving...' : 'Save',
          width: 80,
          height: 36,
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
      backgroundColor: AppColors.surface,
      title: Text(
        'Edit ${widget.apiKey.provider.toUpperCase()} Key',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernTextField(
              initialValue: _priority.toString(),
              hintText: 'Priority (0-100)',
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
        ModernButton(
          onPressed: _saving ? () {} : _updateKey,
          label: _saving ? 'Updating...' : 'Update',
          width: 80,
          height: 36,
        ),
      ],
    );
  }
}
