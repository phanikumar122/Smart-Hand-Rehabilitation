import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _autoReconnect = true;
  final StorageService _storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('App appearance'),
            value: _darkMode,
            onChanged: (val) {
              setState(() => _darkMode = val);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dark mode is enforced by medical standard.')),
              );
              // Reset to true to enforce premium dark mode as per requirements
              setState(() => _darkMode = true);
            },
            activeColor: AppTheme.primaryColor,
          ),
          SwitchListTile(
            title: const Text('Auto Reconnect'),
            subtitle: const Text('Automatically connect to last known glove'),
            value: _autoReconnect,
            onChanged: (val) => setState(() => _autoReconnect = val),
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear All Session Data'),
            subtitle: const Text('Permanently delete all saved rehab history'),
            trailing: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Data'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        await _storageService.clearSessions();
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data cleared')),
                          );
                        }
                      },
                      child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
