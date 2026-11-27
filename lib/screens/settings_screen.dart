import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../l10n/app_locale_controller.dart';

import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import '../widgets/calibration_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final languages = AppLocaleScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.settings)),
      body: ResponsivePage(
        maxWidth: 720,
        child: ListView(
          children: [
            SectionHeader(title: context.strings.language),
            const SizedBox(height: 10),
            ClinicalCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<String>(
                groupValue: languages.locale?.languageCode ?? 'system',
                onChanged: (code) async {
                  if (code == null) return;
                  try {
                    await languages.setLocale(
                      code == 'system' ? null : Locale(code),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.message(error))),
                    );
                  }
                },
                child: Column(
                  children: [
                    for (final option in [
                      ('system', context.strings.deviceLanguage),
                      ('en', 'English'),
                      ('te', 'తెలుగు'),
                      ('hi', 'हिन्दी'),
                    ])
                      RadioListTile<String>(
                        value: option.$1,
                        title: Text(option.$2),
                        selected:
                            (languages.locale?.languageCode ?? 'system') ==
                            option.$1,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: context.strings.appearance),
            const SizedBox(height: 10),
            ClinicalCard(
              child: AnimatedBuilder(
                animation: AppThemeController.instance,
                builder: (context, _) {
                  final controller = AppThemeController.instance;
                  final labels = {
                    ThemeMode.system: context.strings.systemTheme,
                    ThemeMode.light: context.strings.lightTheme,
                    ThemeMode.dark: context.strings.darkTheme,
                  };
                  if (context.strings.localeName != 'en' ||
                      MediaQuery.textScalerOf(context).scale(14) > 21) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in labels.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: controller.mode == entry.key,
                            onSelected: (_) => controller.setMode(entry.key),
                          ),
                      ],
                    );
                  }
                  return SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(context.strings.systemTheme),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(context.strings.lightTheme),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(context.strings.darkTheme),
                      ),
                    ],
                    selected: {controller.mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        controller.setMode(value.first),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: context.strings.connection),
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
                    title: Text(context.strings.autoReconnect),
                    subtitle: Text(context.strings.autoReconnectHint),
                    secondary: const Icon(Icons.sync_rounded),
                    value: provider.autoReconnect,
                    onChanged: (value) async {
                      try {
                        await provider.setAutoReconnect(value);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.message(error))),
                        );
                      }
                    },
                  ),
                  if (provider.isConnected) ...[
                    const Divider(height: 1),
                    if (!provider.supportsProtocol)
                      SwitchListTile(
                        title: Text(context.strings.legacyFirmware),
                        subtitle: Text(context.strings.legacyFirmwareHint),
                        value: provider.legacyFirmware,
                        onChanged:
                            provider.commandPending ||
                                provider.isSessionActive ||
                                provider.supportsProtocol
                            ? null
                            : (value) async {
                                try {
                                  await provider.setLegacyFirmwareMode(value);
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.message(error)),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    if (!provider.supportsProtocol) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      title: Text(context.strings.disconnectGlove),
                      subtitle: Text(
                        provider.connectedDevice?.displayName ??
                            context.strings.connectedDevice,
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
            const CalibrationPanel(),
            const SizedBox(height: 24),
            SectionHeader(
              title: context.strings.dataPrivacy,
              caption: context.strings.storedOnDevice,
            ),
            const SizedBox(height: 10),
            ClinicalCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                title: Text(context.strings.clearSessionData),
                subtitle: Text(context.strings.clearSessionDataHint),
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
                      title: Text(context.strings.clearData),
                      content: Text(context.strings.cannotUndo),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(context.strings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(context.strings.clear),
                        ),
                      ],
                    ),
                  );
                  if (clear != true || !context.mounted) return;
                  try {
                    await StorageService().clearSessions();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.strings.historyCleared)),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.strings.historyClearFailed),
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
