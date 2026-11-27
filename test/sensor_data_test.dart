import 'package:flutter_test/flutter_test.dart';
import 'package:smart_glove_app/models/sensor_data.dart';

void main() {
  test('parses six protocol values', () {
    final data = SensorData.fromCsv('10,20,30,40,90,1023')!;
    expect(
      [data.thumb, data.index, data.middle, data.ring, data.pinky, data.grip],
      [10, 20, 30, 40, 90, 1023],
    );
  });
  test('rejects short and long lines', () {
    expect(SensorData.fromCsv('1,2,3'), isNull);
    expect(SensorData.fromCsv('1,2,3,4,5,6,7'), isNull);
  });
  test('rejects letters', () {
    expect(SensorData.fromCsv('a,2,3,4,5,6'), isNull);
  });
  test('rejects out-of-range angles and force', () {
    for (final line in [
      '91,2,3,4,5,6',
      '1,-1,3,4,5,6',
      '1,2,3,4,5,1024',
      '1,2,3,4,5,-1',
    ]) {
      expect(SensorData.fromCsv(line), isNull, reason: line);
    }
  });
  test('accepts extra whitespace', () {
    expect(SensorData.fromCsv(' 1, 2 ,3, 4,5, 6 ')?.grip, 6);
  });
  test('accepts CRLF and real zero readings', () {
    expect(SensorData.fromCsv('0,0,0,0,0,0\r\n')?.thumb, 0);
  });
  test('rejects signed and hexadecimal telemetry fields', () {
    for (final frame in ['0x10,2,3,4,5,6', '1,2,3,4,5,0x200', '+1,2,3,4,5,6']) {
      expect(SensorData.fromCsv(frame), isNull, reason: frame);
    }
  });
}
