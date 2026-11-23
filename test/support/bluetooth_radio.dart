import 'dart:async';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

/// Platform boundary for UI tests; it provides device metadata, never readings.
class BluetoothRadio extends FlutterClassicBluetoothPlatform {
  final adapterEvents = StreamController<BtcAdapterState>.broadcast(sync: true);
  final discoveryEvents = StreamController<BtcDevice>.broadcast(sync: true);
  final discoveryStateEvents = StreamController<bool>.broadcast(sync: true);
  final permissionRequests = <Set<BtcPermission>>[];
  int scans = 0;
  BtcPermissionStatus permission = BtcPermissionStatus.granted;
  @override
  Future<BtcPermissionStatus> requestPermissions(
    Set<BtcPermission> permissions,
  ) async {
    permissionRequests.add(permissions);
    return permission;
  }

  @override
  Future<bool> isEnabled() async => true;
  @override
  Future<bool> isLocationServiceRequired() async => false;
  @override
  Future<List<BtcDevice>> getPairedDevices() async => const [
    BtcDevice(
      address: '00:11:22:33:44:55',
      name: 'Glove',
      bondState: BtcBondState.bonded,
    ),
  ];
  @override
  Stream<BtcAdapterState> adapterState() => adapterEvents.stream;
  @override
  Stream<BtcDevice> discoveryResults() => discoveryEvents.stream;
  @override
  Stream<bool> discoveryState() => discoveryStateEvents.stream;
  @override
  Future<void> startDiscovery() async {
    scans++;
    discoveryStateEvents.add(true);
  }

  @override
  Future<void> stopDiscovery() async => discoveryStateEvents.add(false);
  Future<void> close() async {
    await adapterEvents.close();
    await discoveryEvents.close();
    await discoveryStateEvents.close();
  }
}
