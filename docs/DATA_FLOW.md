# Data Flow and Runtime State

This document describes the implemented path from the glove’s analog sensors to the Flutter interface and saved rehabilitation summaries.

## 1. Sensor acquisition and calibration

The firmware reads five flex sensors and one force-sensitive resistor:

```text
A0  Thumb flex
A1  Index flex
A2  Middle flex
A3  Ring flex
A6  Pinky flex
A7  Grip pressure
```

During startup, the firmware waits three seconds and captures one baseline reading for every flex sensor. The user should keep the hand flat during this period.

For each finger:

```text
delta = abs(currentReading - baseline)
angle = constrain(map(delta, 0, 150, 0, 90), 0, 90)
```

The resulting angle is a calibrated relative movement value, not a clinical joint-angle measurement.

## 2. Firmware transmission

`arduino/smart_glove/smart_glove.ino` transmits at 10 Hz (`SEND_INTERVAL = 100 ms`) through a software serial link at 9600 baud.

Each frame contains six comma-separated decimal integers:

```text
thumb,index,middle,ring,pinky,grip\n
```

Example:

```text
12,28,40,33,18,642
```

The newline is the frame boundary. USB Serial also prints the same values at 115200 baud for diagnostics.

## 3. Bluetooth connection boundary

`lib/services/glove_connection.dart` isolates the Bluetooth plugin behind `GloveConnection`:

- `input` provides incoming byte chunks.
- `states` reports connection state changes.
- `write` and `flush` send complete haptic commands.
- `close` shuts down and disposes the native connection.

This boundary allows provider tests to use a deterministic fake serial link without physical hardware.

## 4. Byte framing and validation

`GloveDataProvider` owns the receive buffer because Bluetooth chunks do not necessarily match firmware frames. One frame may be split across chunks, and one chunk may contain several frames.

Processing rules:

1. Append safe bytes until newline byte `10` is received.
2. Ignore carriage return and horizontal tab as permitted whitespace.
3. Discard a frame containing non-ASCII/control bytes.
4. Discard an oversized frame after 2048 bytes until its newline.
5. Parse only complete frames.
6. Require exactly six integers.
7. Require every finger angle to be `0..90`.
8. Require grip pressure to be `0..1023`.

Malformed input never replaces the last valid reading.

## 5. Live-data lifecycle

A connection alone is not treated as a live signal.

`hasLiveData` is true only when:

- the Bluetooth connection exists;
- at least one valid frame has been parsed; and
- the latest valid packet is less than 1.5 seconds old.

A watchdog runs every 500 ms. When a packet becomes stale, the current reading is cleared and the UI changes to **No signal** instead of presenting old values as live.

History retains at most:

- the latest five minutes; and
- 3000 readings.

The exposed history list is immutable to UI callers.

## 6. UI state propagation

`GloveDataProvider` extends `ChangeNotifier` and is injected with Provider at application startup.

Screens watch only the state they display:

- Today: signal, grip, finger mobility, and haptic controls
- Live: animated hand, pressure feedback, and sensor detail
- Session: timer, reading count, live grip, and lifecycle controls
- Progress: measured chart history and locally saved sessions

Sensor animations interpolate between validated readings but never create data or delay provider state changes. When live data becomes stale, the numeric UI is removed.

## 7. Rehabilitation session lifecycle

A session can start only when a recent valid packet exists.

At start, the provider resets:

- start time;
- elapsed time;
- reading count;
- maximum grip;
- movement total; and
- status message.

Only packets received after session start contribute to metrics.

At stop:

- A session with zero readings is discarded.
- `maxGrip` is the highest recorded grip value.
- `averageMovement` is the integer average across all five finger values and all recorded frames.
- The summary is persisted only when `readingCount > 0`.

The timer belongs to the provider, so navigating between tabs does not reset elapsed time.

## 8. Local persistence

`StorageService` uses SharedPreferences with the key:

```text
rehab_sessions
```

Each JSON record contains:

```text
id
startTime
duration
maxGrip
averageMovement
readingCount
```

Malformed records are skipped. Legacy records without a positive reading count are not shown because they cannot prove that live glove data was recorded.

The appearance setting is stored separately under:

```text
theme_mode
```

No session information is uploaded to a server.

## 9. Haptic command path

The UI sends only commands matching:

```text
<VIB:(ALL|1|2|3|4|5),(0|1)>
```

Examples:

```text
<VIB:ALL,1>
<VIB:2,0>
```

The provider writes and flushes the entire command. The firmware parses bytes between `<` and `>`, then switches the requested motor output.

The current firmware does not return an acknowledgement, so the UI describes the last command sent rather than claiming confirmed motor state.

## 10. Disconnect and reconnect behavior

Manual disconnect:

- cancels watchdog and reconnect timers;
- clears connection, live data, history, and buffers;
- closes the native link; and
- stops an active session, saving it only if readings exist.

When auto reconnect is enabled, an unexpected link loss retries up to three times at two-second intervals. A manual disconnect or disabled setting cancels pending retries.

## 11. Test coverage

Automated tests verify:

- split and combined frame assembly;
- invalid input and overflow recovery;
- accepted ranges and whitespace;
- stale-data clearing;
- bounded immutable history;
- reconnect timing and cancellation;
- exact haptic command bytes;
- session persistence and metrics;
- connection-gated navigation;
- missing-data UI semantics; and
- phone/landscape layouts at 200% text scale.