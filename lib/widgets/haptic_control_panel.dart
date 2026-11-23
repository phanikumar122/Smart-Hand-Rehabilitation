import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../models/firmware_status.dart';
import '../widgets/app_components.dart';

class HapticControlPanel extends StatefulWidget {
  const HapticControlPanel({super.key});
  @override
  State<HapticControlPanel> createState() => _HapticControlPanelState();
}

class _HapticControlPanelState extends State<HapticControlPanel> {
  bool _sending = false;
  String? _error;
  static const _fingers = ['Thumb', 'Index', 'Middle', 'Ring', 'Pinky'];

  Future<void> _send(bool enabled, [int? finger]) async {
    final provider = context.read<GloveDataProvider>();
    if (!provider.isConnected || _sending || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (finger == null) {
        await provider.vibrateAll(enabled);
      } else {
        await provider.vibrateFinger(finger, enabled);
      }
      if (!mounted) return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final enabled =
        provider.isConnected &&
        !_sending &&
        !provider.commandPending &&
        provider.calibrationPhase == CalibrationPhase.idle &&
        (provider.firmware != null || provider.legacyFirmware);
    return ClinicalCard(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Text(
                'Vibration Controls',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                provider.legacyFirmware
                    ? 'Legacy firmware: commands are sent without state confirmation.'
                    : 'Shows outputs reported by the glove. A motor command selects Manual mode.',
              ),
              const SizedBox(height: 12),
              Text(
                'Mode: ${provider.hapticMode == null
                    ? 'Unknown'
                    : provider.hapticMode == HapticMode.manual
                    ? 'Manual'
                    : 'Automatic'}',
              ),
              if (!provider.legacyFirmware)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: enabled
                          ? () => _mode(HapticMode.automatic)
                          : null,
                      child: const Text('Automatic'),
                    ),
                    OutlinedButton(
                      onPressed: enabled
                          ? () => _mode(HapticMode.manual)
                          : null,
                      child: const Text('Manual'),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: enabled ? () => _send(true) : null,
                    child: const Text('All on'),
                  ),
                  OutlinedButton(
                    onPressed: enabled ? () => _send(false) : null,
                    child: const Text('All off'),
                  ),
                ],
              ),
              if (_sending || provider.commandPending)
                const LinearProgressIndicator(),
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_fingers[i]),
                  subtitle: Text(
                    (provider.confirmedMotorMask == null
                            ? 'Output unknown'
                            : provider.confirmedMotorMask! & (1 << i) != 0
                            ? 'Reported output: On'
                            : 'Reported output: Off') +
                        (provider.commandState == CommandState.sending ||
                                provider.commandState ==
                                    CommandState.sentUnconfirmed
                            ? '\nRequested: ${provider.requestedMotorMask & (1 << i) != 0 ? 'On' : 'Off'}'
                            : ''),
                  ),
                  value: (provider.confirmedMotorMask ?? 0) & (1 << i) != 0,
                  onChanged: enabled ? (value) => _send(value, i + 1) : null,
                ),
              ],
              if (provider.commandMessage != null)
                Semantics(
                  liveRegion: true,
                  child: Text(provider.commandMessage!),
                ),
              if (provider.safetyMessage != null)
                Text(
                  provider.safetyMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mode(HapticMode mode) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<GloveDataProvider>().setHapticMode(mode);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
