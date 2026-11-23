import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Auto Reconnect'),
              subtitle: const Text(
                'Retry a lost connection up to 3 times, 2 seconds apart.',
              ),
              value: provider.autoReconnect,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (value) async {
                try {
                  await provider.setAutoReconnect(value);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
            ),
            if (provider.isConnected)
              ListTile(
                title: const Text('Disconnect Glove'),
                leading: const Icon(Icons.bluetooth_disabled),
                onTap: () async {
                  await provider.disconnect();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            const Divider(),
            ListTile(
              title: const Text('Clear All Session Data'),
              subtitle: const Text(
                'Permanently delete saved rehabilitation history',
              ),
              trailing: const Icon(
                Icons.delete_forever,
                color: AppTheme.errorColor,
              ),
              onTap: () async {
                final clear = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Clear Data'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (clear != true) return;
                try {
                  await StorageService().clearSessions();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session history cleared.')),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not clear history: $error')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
