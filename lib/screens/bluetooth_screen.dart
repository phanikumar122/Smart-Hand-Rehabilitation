import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import 'main_wrapper.dart';
import 'settings_screen.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});
  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  final List<BtcDevice> _devicesList = [];
  StreamSubscription<BtcAdapterState>? _adapterSubscription;
  StreamSubscription<BtcDevice>? _discoverySubscription;
  StreamSubscription<bool>? _discoveryStateSubscription;
  bool _enabled = false;
  bool _isDiscovering = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = error.toString();
      _busy = false;
      _isDiscovering = false;
    });
  }

  Future<bool> _requestPermissions() async {
    final result = await _bluetooth.requestPermissions(
      permissions: const {BtcPermission.scan, BtcPermission.connect},
    );
    if (result == BtcPermissionStatus.granted ||
        result == BtcPermissionStatus.notRequired) {
      return true;
    }
    _showError(
      result == BtcPermissionStatus.permanentlyDenied
          ? 'Bluetooth permission denied. Enable Nearby devices in app settings.'
          : 'Bluetooth permission is required to connect the glove.',
    );
    return false;
  }

  Future<void> _initialize() async {
    try {
      if (!await _requestPermissions() || !mounted) return;
      _adapterSubscription = _bluetooth.adapterState.listen((state) {
        if (!mounted) return;
        setState(() => _enabled = state == BtcAdapterState.on);
        if (_enabled) unawaited(_getPairedDevices());
      }, onError: _showError);
      _discoveryStateSubscription = _bluetooth.discoveryState.listen((value) {
        if (!mounted) return;
        setState(() => _isDiscovering = value);
      }, onError: _showError);
      _discoverySubscription = _bluetooth.discoveryResults.listen((device) {
        if (!mounted) return;
        setState(() {
          final index = _devicesList.indexWhere(
            (item) => item.address == device.address,
          );
          if (index < 0) {
            _devicesList.add(device);
          } else {
            _devicesList[index] = _devicesList[index].mergedWith(device);
          }
        });
      }, onError: _showError);
      final enabled = await _bluetooth.isEnabled();
      if (!mounted) return;
      setState(() => _enabled = enabled);
      if (enabled) await _getPairedDevices();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _getPairedDevices() async {
    try {
      final devices = await _bluetooth.getPairedDevices();
      if (!mounted) return;
      setState(() {
        _devicesList.clear();
        _devicesList.addAll(devices);
        _error = null;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _startDiscovery() async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _requestPermissions() || !mounted) return;
      // Permission denial on launch can be recovered without recreating the screen.
      if (_adapterSubscription == null) {
        await _initialize();
      }
      if (!mounted) return;
      if (!await _bluetooth.isEnabled()) {
        _showError('Enable Bluetooth before scanning.');
        return;
      }
      if (await _bluetooth.isLocationServiceRequired() &&
          !await _bluetooth.isLocationServiceEnabled()) {
        _showError('Enable system Location to scan on Android 11 or earlier.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _isDiscovering = true;
        _busy = false;
      });
      await _bluetooth.startDiscovery();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _connectToDevice(BtcDevice device) async {
    final provider = context.read<GloveDataProvider>();
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _bluetooth.stopDiscovery();
      final connected = await provider.connectToDevice(device);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _isDiscovering = false;
      });
      if (connected && provider.isConnected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      } else {
        _showError(
          provider.connectionError ??
              'Glove connection closed before it was ready.',
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  @override
  void dispose() {
    unawaited(_adapterSubscription?.cancel());
    unawaited(_discoverySubscription?.cancel());
    unawaited(_discoveryStateSubscription?.cancel());
    unawaited(_bluetooth.stopDiscovery().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GloveDataProvider>();
    final connecting = _busy || provider.isConnecting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Glove'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(
                _enabled ? 'Bluetooth enabled' : 'Bluetooth disabled',
              ),
              trailing: TextButton(
                onPressed: connecting
                    ? null
                    : () async {
                        try {
                          await _bluetooth.enableBluetooth();
                          final enabled = await _bluetooth.isEnabled();
                          if (!mounted) return;
                          setState(() => _enabled = enabled);
                          if (_adapterSubscription == null) {
                            await _initialize();
                          } else if (enabled) {
                            await _getPairedDevices();
                          }
                        } catch (error) {
                          _showError(error);
                        }
                      },
                child: const Text('Enable'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: Text('Paired and discovered devices')),
                  TextButton(
                    onPressed: connecting || _isDiscovering
                        ? null
                        : _startDiscovery,
                    child: const Text('Scan'),
                  ),
                  IconButton(
                    tooltip: 'Refresh paired devices',
                    onPressed: connecting ? null : _getPairedDevices,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (_isDiscovering || connecting || provider.isReconnecting)
              const LinearProgressIndicator(),
            if (provider.isReconnecting)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Reconnecting to glove…'),
              ),
            if (_error ?? provider.connectionError case final String error)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (provider.sessionMessage case final String message)
              Padding(padding: const EdgeInsets.all(12), child: Text(message)),
            Expanded(
              child: _devicesList.isEmpty
                  ? const Center(
                      child: Text(
                        'Pair your glove in Android Bluetooth settings,\nthen refresh or scan.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        final device = _devicesList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(device.displayName),
                            subtitle: Text(device.address),
                            trailing: ElevatedButton(
                              onPressed: connecting
                                  ? null
                                  : () => _connectToDevice(device),
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_error != null)
              TextButton(
                onPressed: _bluetooth.openAppSettings,
                child: const Text('Open app settings'),
              ),
          ],
        ),
      ),
    );
  }
}
