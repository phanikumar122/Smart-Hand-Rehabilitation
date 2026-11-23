import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/firmware_status.dart';
import '../providers/glove_data_provider.dart';
import 'app_components.dart';

class CalibrationPanel extends StatelessWidget {
  const CalibrationPanel({super.key});

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // The provider keeps the command/calibration error visible across screens.
    }
  }

  @override
  Widget build(BuildContext context) {
    final glove = context.watch<GloveDataProvider>();
    final phase = glove.calibrationPhase;
    final enabled =
        glove.isConnected &&
        glove.firmware != null &&
        !glove.commandPending &&
        !glove.isSessionActive;
    final message = switch (phase) {
      CalibrationPhase.open =>
        'Capturing open hand. Hold still with the FSR unloaded.',
      CalibrationPhase.closed =>
        'Capturing bent hand. Hold still without forcing your fingers.',
      CalibrationPhase.openReady => 'Open hand captured. Bend each finger comfortably, then capture the bent hand.',
      CalibrationPhase.ready =>
        'Both positions captured. Save calibration to use these readings.',
      CalibrationPhase.saving =>
        'Saving calibration. Keep the glove powered on.',
      CalibrationPhase.failed => 'Capture failed. Retry with a steady hand, or cancel to keep the previous calibration.',
      CalibrationPhase.idle =>
        glove.calibrationValid
            ? 'Valid calibration loaded. Recalibrate after moving sensors or changing the glove fit.'
            : 'Calibration is required before recording with upgraded firmware.',
    };
    return ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Glove calibration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            glove.firmware == null
                ? glove.legacyFirmware
                      ? 'Upgrade the glove firmware to enable guided calibration.'
                      : 'Connect the glove to read its firmware and calibration status.'
                : 'Firmware ${glove.firmware!.version} · ${glove.firmware!.saved ? 'Saved calibration' : 'Calibration not saved'}',
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Open your hand comfortably and remove pressure from the grip sensor.\n'
            '2. Capture open hand and wait for completion.\n'
            '3. Bend your fingers within a comfortable range, capture, then save.\n'
            'Each capture takes about 1.3 seconds. Movement values are normalized estimates.',
          ),
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(message)),
          if (glove.calibrationActive || glove.commandPending) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (glove.isSessionActive)
            const Text('Stop the recording session before calibrating.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: enabled && !glove.calibrationActive
                    ? () => _run(glove.calibrateOpen)
                    : null,
                child: const Text('Capture open hand'),
              ),
              OutlinedButton(
                onPressed: enabled && phase == CalibrationPhase.openReady
                    ? () => _run(glove.calibrateClosed)
                    : null,
                child: const Text('Capture bent hand'),
              ),
              ElevatedButton(
                onPressed: enabled && phase == CalibrationPhase.ready
                    ? () => _run(glove.saveCalibration)
                    : null,
                child: const Text('Save calibration'),
              ),
              TextButton(
                onPressed:
                    enabled &&
                        phase != CalibrationPhase.idle &&
                        phase != CalibrationPhase.saving
                    ? () => _run(glove.cancelCalibration)
                    : null,
                child: const Text('Cancel calibration'),
              ),
              TextButton(
                onPressed: enabled && !glove.calibrationActive
                    ? () => _run(glove.resetCalibration)
                    : null,
                child: const Text('Reset calibration'),
              ),
              TextButton(
                onPressed:
                    glove.isConnected &&
                        !glove.commandPending &&
                        !glove.legacyFirmware
                    ? () => _run(glove.refreshFirmwareStatus)
                    : null,
                child: const Text('Refresh status'),
              ),
            ],
          ),
          if (glove.calibrationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                glove.calibrationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (glove.commandMessage != null) Text(glove.commandMessage!),
        ],
      ),
    );
  }
}
