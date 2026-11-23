import 'dart:async';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../widgets/app_components.dart';
import 'app_shell.dart';
import 'settings_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});
  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
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
        _devicesList
          ..clear()
          ..addAll(devices);
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
      if (_adapterSubscription == null) await _initialize();
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
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
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

  Future<void> _enableBluetooth() async {
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: ResponsivePage(
        maxWidth: 760,
        child: ListView(
          children: [
            AppPageHeader(
              eyebrow: 'Step 1 of 3 · Connect',
              title: 'Connect Glove',
              subtitle: 'Connect your glove to begin live movement tracking.',
              trailing: IconButton.filledTonal(
                tooltip: 'Settings',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ClinicalCard(
              color: _enabled ? colors.primaryContainer : colors.errorContainer,
              child: _BluetoothStatus(
                enabled: _enabled,
                connecting: connecting,
                onEnable: _enableBluetooth,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                const SizedBox(
                  width: 210,
                  child: SectionHeader(
                    title: 'Nearby devices',
                    caption: 'Paired and discovered devices',
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: connecting || _isDiscovering
                          ? null
                          : _startDiscovery,
                      icon: const Icon(Icons.radar_rounded),
                      label: const Text('Scan'),
                    ),
                    IconButton(
                      tooltip: 'Refresh paired devices',
                      onPressed: connecting ? null : _getPairedDevices,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ),
            if (_isDiscovering || connecting || provider.isReconnecting)
              const LinearProgressIndicator(),
            if (provider.isReconnecting)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Reconnecting to glove…'),
              ),
            if (_error ?? provider.connectionError case final String error)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClinicalCard(
                  padding: const EdgeInsets.all(14),
                  color: colors.errorContainer,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: colors.error),
                      const SizedBox(width: 10),
                      Expanded(child: Text(error)),
                    ],
                  ),
                ),
              ),
            if (provider.sessionMessage case final String message)
              Padding(padding: const EdgeInsets.all(8), child: Text(message)),
            if (_devicesList.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyState(
                  icon: Icons.bluetooth_searching_rounded,
                  title: 'Your glove will appear here',
                  message: 'Pair it in Android Bluetooth settings, then refresh or scan.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: _devicesList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _DeviceCard(
                  device: _devicesList[index],
                  connecting: connecting,
                  onConnect: _connectToDevice,
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

class _BluetoothStatus extends StatelessWidget {
  const _BluetoothStatus({
    required this.enabled,
    required this.connecting,
    required this.onEnable,
  });
  final bool enabled;
  final bool connecting;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (enabled ? colors.primary : colors.error).withValues(
              alpha: 0.14,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            enabled
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_disabled_rounded,
            color: enabled ? colors.primary : colors.error,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enabled ? 'Bluetooth enabled' : 'Bluetooth disabled',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                enabled
                    ? 'Ready to discover your glove.'
                    : 'Turn Bluetooth on to continue.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
    final enable = TextButton(
      onPressed: connecting ? null : onEnable,
      child: const Text('Enable'),
    );
    if (MediaQuery.textScalerOf(context).scale(16) > 24) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          status,
          Align(alignment: Alignment.centerRight, child: enable),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: status),
        const SizedBox(width: 8),
        enable,
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.connecting,
    required this.onConnect,
  });
  final BtcDevice device;
  final bool connecting;
  final ValueChanged<BtcDevice> onConnect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClinicalCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.front_hand_rounded, color: colors.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  device.address,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: connecting ? null : () => onConnect(device),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
