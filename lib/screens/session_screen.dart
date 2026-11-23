import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final seconds = provider.sessionElapsed.inSeconds;
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Rehabilitation Session')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(provider.status),
                Text('Grip: ${provider.currentData?.grip.toString() ?? '--'}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: provider.isSavingSession
                      ? null
                      : provider.isSessionActive
                      ? () async {
                          await provider.stopSession();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.sessionMessage ?? 'Session stopped.',
                              ),
                            ),
                          );
                        }
                      : provider.canStartSession
                      ? () => provider.startSession()
                      : null,
                  child: Text(
                    provider.isSavingSession
                        ? 'Saving…'
                        : provider.isSessionActive
                        ? 'Stop Session'
                        : 'Start Session',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  provider.isSessionActive
                      ? '${provider.sessionReadingCount} readings recorded'
                      : provider.canStartSession
                      ? 'Ready to begin'
                      : 'Connect the glove and wait for a live signal.',
                ),
                if (provider.sessionMessage case final String message)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(message, textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
