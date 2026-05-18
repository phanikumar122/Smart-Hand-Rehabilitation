import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/glove_data_provider.dart';
import '../utils/theme.dart';
import 'main_wrapper.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_ON) {
          _getBondedDevices();
        }
      });
    });

    _getBondedDevices();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    
    if (statuses[Permission.bluetoothConnect]!.isGranted) {
      _getBondedDevices();
    }
  }

  void _getBondedDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = devices;
      });
    } catch (e) {
      if (kDebugMode) print('Error getting bonded devices: $e');
    }
  }

  void _startDiscovery() {
    setState(() => _devicesList.clear());
    FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = _devicesList.indexWhere((element) => element.address == r.device.address);
        if (existingIndex >= 0) {
          _devicesList[existingIndex] = r.device;
        } else {
          _devicesList.add(r.device);
        }
      });
    }).onDone(() {
      setState(() => _isDiscovering = false);
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    final provider = Provider.of<GloveDataProvider>(context, listen: false);
    await provider.connectToDevice(device);
    
    if (provider.isConnected && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Glove'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Bluetooth'),
            value: _bluetoothState.isEnabled,
            onChanged: (bool value) {
              future() async {
                if (value) {
                  await FlutterBluetoothSerial.instance.requestEnable();
                } else {
                  await FlutterBluetoothSerial.instance.requestDisable();
                }
              }
              future().then((_) {
                setState(() {});
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          ListTile(
            title: const Text("Paired Devices", style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getBondedDevices,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                bool isHC05 = device.name?.contains('HC-05') ?? false;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.bluetooth,
                      color: isHC05 ? AppTheme.primaryColor : Colors.grey,
                    ),
                    title: Text(device.name ?? "Unknown Device"),
                    subtitle: Text(device.address),
                    trailing: Consumer<GloveDataProvider>(
                      builder: (context, provider, child) {
                        if (provider.isConnecting) {
                          return const CircularProgressIndicator();
                        }
                        return ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Connect'),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainWrapper()),
                );
              },
              child: const Text('Continue without Glove (Demo Mode)', style: TextStyle(color: Colors.grey)),
            ),
          )
        ],
      ),
    );
  }
}
