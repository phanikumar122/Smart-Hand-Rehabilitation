enum HapticMode { automatic, manual }

enum CommandState { idle, sending, confirmed, failed, sentUnconfirmed }

enum CalibrationPhase { idle, open, closed, openReady, ready, saving, failed }

class FirmwareStatus {
  const FirmwareStatus({
    required this.version,
    required this.mode,
    required this.valid,
    required this.phase,
    required this.saved,
    required this.motorMask,
  });
  final String version;
  final HapticMode mode;
  final bool valid;
  final CalibrationPhase phase;
  final bool saved;
  final int motorMask;

  static FirmwareStatus? fromFields(List<String> fields) {
    if (fields.length != 6 ||
        !RegExp(r'^\d+\.\d+(?:\.\d+)?$').hasMatch(fields[0]) ||
        !['AUTO', 'MANUAL'].contains(fields[1]) ||
        !['0', '1'].contains(fields[2]) ||
        !['0', '1'].contains(fields[4])) {
      return null;
    }
    const phases = {
      'IDLE': CalibrationPhase.idle,
      'OPEN': CalibrationPhase.open,
      'CLOSED': CalibrationPhase.closed,
      'OPEN_READY': CalibrationPhase.openReady,
      'READY': CalibrationPhase.ready,
      'SAVING': CalibrationPhase.saving,
      'FAILED': CalibrationPhase.failed,
    };
    final phase = phases[fields[3]];
    final mask = parseMotorMask(fields[5]);
    if (phase == null || mask == null) return null;
    return FirmwareStatus(
      version: fields[0],
      mode: fields[1] == 'AUTO' ? HapticMode.automatic : HapticMode.manual,
      valid: fields[2] == '1',
      phase: phase,
      saved: fields[4] == '1',
      motorMask: mask,
    );
  }

  static int? parseMotorMask(String text) {
    if (!RegExp(r'^[0-9]{1,2}$').hasMatch(text)) return null;
    final mask = int.parse(text, radix: 10);
    return mask <= 31 ? mask : null;
  }
}
