import 'package:flutter/material.dart';
import '../screens/api_key_management_screen.dart';

/// A settings tile that navigates to API Key Management screen
class ApiKeySettingsTile extends StatelessWidget {
  final String userId;
  final String baseUrl;

  const ApiKeySettingsTile({
    super.key,
    required this.userId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: const Text('API Keys'),
      subtitle: const Text('Manage your AI provider API keys'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ApiKeyManagementScreen(userId: userId, baseUrl: baseUrl),
          ),
        );
      },
    );
  }
}
