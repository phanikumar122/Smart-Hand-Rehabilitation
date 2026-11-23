import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';

class VibrationPanel extends StatefulWidget {
  const VibrationPanel({super.key});
  @override
  State<VibrationPanel> createState() => _VibrationPanelState();
}

class _VibrationPanelState extends State<VibrationPanel> {
  final List<bool?> _requested = List.filled(5, null);
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
      setState(() {
        if (finger == null) {
          _requested.fillRange(0, 5, enabled);
        } else {
          _requested[finger - 1] = enabled;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<GloveDataProvider>().isConnected && !_sending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Vibration Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Shows commands sent. The glove does not confirm motor state.',
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
            if (_sending) const LinearProgressIndicator(),
            for (var i = 0; i < 5; i++)
              SwitchListTile(
                title: Text(_fingers[i]),
                subtitle: Text(
                  _requested[i] == null
                      ? 'No command sent'
                      : _requested[i]!
                      ? 'Last command: On'
                      : 'Last command: Off',
                ),
                value: _requested[i] ?? false,
                onChanged: enabled ? (value) => _send(value, i + 1) : null,
              ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}
