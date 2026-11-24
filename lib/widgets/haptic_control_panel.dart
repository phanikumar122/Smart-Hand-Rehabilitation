import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

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
                context.strings.vibrationControls,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                provider.legacyFirmware
                    ? context.strings.legacyUnconfirmed
                    : context.strings.motorManualHint,
              ),
              const SizedBox(height: 12),
              Text(
                context.strings.modeLabel(
                  provider.hapticMode == null
                      ? context.strings.unknown
                      : provider.hapticMode == HapticMode.manual
                      ? context.strings.manual
                      : context.strings.automatic,
                ),
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
                      child: Text(context.strings.automatic),
                    ),
                    OutlinedButton(
                      onPressed: enabled
                          ? () => _mode(HapticMode.manual)
                          : null,
                      child: Text(context.strings.manual),
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
                    child: Text(context.strings.allOn),
                  ),
                  OutlinedButton(
                    onPressed: enabled ? () => _send(false) : null,
                    child: Text(context.strings.allOff),
                  ),
                ],
              ),
              if (_sending || provider.commandPending)
                const LinearProgressIndicator(),
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.strings.fingerName(i)),
                  subtitle: Text(
                    (provider.confirmedMotorMask == null
                            ? context.strings.unconfirmed
                            : provider.confirmedMotorMask! & (1 << i) != 0
                            ? context.strings.on
                            : context.strings.off) +
                        (provider.commandState == CommandState.sending ||
                                provider.commandState ==
                                    CommandState.sentUnconfirmed
                            ? '\n${context.strings.requestedState(provider.requestedMotorMask & (1 << i) != 0 ? context.strings.on : context.strings.off)}'
                            : ''),
                  ),
                  value: (provider.confirmedMotorMask ?? 0) & (1 << i) != 0,
                  onChanged: enabled ? (value) => _send(value, i + 1) : null,
                ),
              ],
              if (provider.commandMessage != null)
                Semantics(
                  liveRegion: true,
                  child: Text(context.message(provider.commandMessage!)),
                ),
              if (provider.safetyMessage != null)
                Text(
                  context.message(provider.safetyMessage!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_error != null)
                Text(
                  context.message(_error!),
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
