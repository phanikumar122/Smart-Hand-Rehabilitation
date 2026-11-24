import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

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
      CalibrationPhase.open => context.strings.holdOpen,
      CalibrationPhase.closed => context.strings.holdBent,
      CalibrationPhase.openReady => context.strings.openCaptured,
      CalibrationPhase.ready => context.strings.positionsCaptured,
      CalibrationPhase.saving => context.strings.savingCalibration,
      CalibrationPhase.failed => context.strings.captureFailed,
      CalibrationPhase.idle =>
        glove.calibrationValid
            ? context.strings.calibratedHint
            : context.strings.captureOpenHint,
    };
    return ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.gloveCalibration,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            glove.firmware == null
                ? glove.legacyFirmware
                      ? context.strings.calibrationNeedsUpgrade
                      : context.strings.connectToCalibrate
                : context.strings.firmwareStatus(
                    glove.firmware!.version,
                    glove.firmware!.saved
                        ? context.strings.calibrationSaved
                        : context.strings.calibrationNotSaved,
                  ),
          ),
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(context.message(message))),
          if (glove.calibrationActive || glove.commandPending) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (glove.isSessionActive)
            Text(context.strings.stopBeforeCalibration),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: enabled && !glove.calibrationActive
                    ? () => _run(glove.calibrateOpen)
                    : null,
                child: Text(context.strings.captureOpen),
              ),
              OutlinedButton(
                onPressed: enabled && phase == CalibrationPhase.openReady
                    ? () => _run(glove.calibrateClosed)
                    : null,
                child: Text(context.strings.captureBent),
              ),
              ElevatedButton(
                onPressed: enabled && phase == CalibrationPhase.ready
                    ? () => _run(glove.saveCalibration)
                    : null,
                child: Text(context.strings.saveCalibration),
              ),
              TextButton(
                onPressed:
                    enabled &&
                        phase != CalibrationPhase.idle &&
                        phase != CalibrationPhase.saving
                    ? () => _run(glove.cancelCalibration)
                    : null,
                child: Text(context.strings.cancelCalibration),
              ),
              TextButton(
                onPressed: enabled && !glove.calibrationActive
                    ? () => _run(glove.resetCalibration)
                    : null,
                child: Text(context.strings.resetCalibration),
              ),
              TextButton(
                onPressed:
                    glove.isConnected &&
                        !glove.commandPending &&
                        !glove.legacyFirmware
                    ? () => _run(glove.refreshFirmwareStatus)
                    : null,
                child: Text(context.strings.refreshStatus),
              ),
            ],
          ),
          if (glove.calibrationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.message(glove.calibrationError!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (glove.commandMessage != null)
            Text(context.message(glove.commandMessage!)),
        ],
      ),
    );
  }
}
