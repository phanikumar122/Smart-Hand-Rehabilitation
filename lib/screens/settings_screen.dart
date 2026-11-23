import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsivePage(
        maxWidth: 720,
        child: ListView(
          children: [
            const AppPageHeader(
              eyebrow: 'Preferences',
              title: 'Make NerveLink yours',
              subtitle:
                  'Adjust appearance, connection behavior, and your data.',
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Appearance',
              caption: 'Choose how the app feels',
            ),
            const SizedBox(height: 10),
            ClinicalCard(
              child: AnimatedBuilder(
                animation: AppThemeController.instance,
                builder: (context, _) => SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {AppThemeController.instance.mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      AppThemeController.instance.setMode(value.first),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Connection',
              caption: 'Keep your glove in reach',
            ),
            const SizedBox(height: 10),
            ClinicalCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    title: const Text('Auto Reconnect'),
                    subtitle: const Text(
                      'Retry a lost connection up to 3 times, 2 seconds apart.',
                    ),
                    secondary: const Icon(Icons.sync_rounded),
                    value: provider.autoReconnect,
                    onChanged: (value) async {
                      try {
                        await provider.setAutoReconnect(value);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                  ),
                  if (provider.isConnected) ...[
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      title: const Text('Disconnect Glove'),
                      subtitle: Text(
                        provider.connectedDevice?.displayName ??
                            'Connected device',
                      ),
                      leading: const Icon(Icons.bluetooth_disabled_rounded),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await provider.disconnect();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Data & privacy',
              caption: 'Saved only on this device',
              action: StatusPill(
                label: 'On-device',
                icon: Icons.shield_outlined,
                tone: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 10),
            ClinicalCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                title: const Text('Clear All Session Data'),
                subtitle: const Text(
                  'Permanently delete saved rehabilitation history',
                ),
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final clear = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      icon: const Icon(Icons.warning_amber_rounded),
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
                      SnackBar(
                        content: Text('Could not clear history: $error'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
