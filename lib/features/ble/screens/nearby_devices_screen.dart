import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/location/location_service.dart';
import '../../../core/ble/ble_connection_service.dart';
import '../../../core/ble/ble_advertise_service.dart';
import '../../../core/ble/ble_scan_service.dart';

class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen> {
  final BleScanService _bleService = BleScanService();
  final BleAdvertiseService _advertiseService = BleAdvertiseService();
  final BleConnectionService _connectionService = BleConnectionService();
  final LocationService _locationService = LocationService();

  StreamSubscription<Uint8List>? _receivedDataSubscription;
  String? _receivedMessage;
  String? _transferStatus;
  String? _sendingDeviceId;

  bool _isAdvertising = false;
  String? _advertiseMessage;
  bool _isAdvertisingBusy = false;
  StreamSubscription<List<ScanResult>>? _resultsSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  final Map<String, ScanResult> _devices = {};

  bool _isScanning = false;
  bool _isLoading = false;
  String? _error;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  String? _locationMessage;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();

    _resultsSubscription = _bleService.scanResults.listen((results) {
      if (!mounted) return;

      setState(() {
        for (final result in results) {
          _devices[result.device.remoteId.str] = result;
        }
      });
    });

    _scanningSubscription = _bleService.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() => _isScanning = scanning);
    });

    _adapterSubscription = _bleService.adapterState.listen((state) {
      if (!mounted) return;
      setState(() => _adapterState = state);
    });

    _receivedDataSubscription = _advertiseService.receivedData.listen((data) {
      if (!mounted) return;

      setState(() {
        _receivedMessage = utf8.decode(data, allowMalformed: true);
      });
    });

    _startScan();
  }

  Future<void> _startAdvertising() async {
    setState(() {
      _isAdvertisingBusy = true;
      _advertiseMessage = null;
    });

    try {
      final message = await _advertiseService.startAdvertising();
      final advertising = await _advertiseService.isAdvertising;

      if (!mounted) return;

      setState(() {
        _isAdvertising = advertising;
        _advertiseMessage = message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _advertiseMessage = 'Advertising failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isAdvertisingBusy = false);
      }
    }
  }

  Future<void> _stopAdvertising() async {
    try {
      await _advertiseService.stopAdvertising();

      if (!mounted) return;

      setState(() {
        _isAdvertising = false;
        _advertiseMessage = 'HERP advertising stopped.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _advertiseMessage = 'Could not stop advertising: $error';
      });
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _error = null;
      _devices.clear();
      _isLoading = true;
    });

    try {
      await _bleService.startScan();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _stopScan() async {
    try {
      await _bleService.stopScan();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _sendTestMessage(ScanResult result) async {
    final deviceId = result.device.remoteId.str;

    setState(() {
      _sendingDeviceId = deviceId;
      _transferStatus = null;
    });

    try {
      final message = await _connectionService.sendTestMessage(result.device);

      if (!mounted) return;

      setState(() {
        _transferStatus = '$deviceId: $message';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _transferStatus = 'Transfer failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _sendingDeviceId = null);
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _gettingLocation = true;
      _locationMessage = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        _locationMessage =
            'Latitude: ${location.latitude}\n'
            'Longitude: ${location.longitude}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationMessage = 'Could not get location: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _gettingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    _resultsSubscription?.cancel();
    _scanningSubscription?.cancel();
    _adapterSubscription?.cancel();
    _receivedDataSubscription?.cancel();
    _bleService.stopScan();
    _advertiseService.stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothOn = _adapterState == BluetoothAdapterState.on;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby HERP Devices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                bluetoothOn ? Icons.bluetooth : Icons.bluetooth_disabled,
              ),
              title: Text(
                bluetoothOn ? 'Bluetooth is enabled' : 'Bluetooth is not ready',
              ),
              subtitle: const Text('Discovery works locally without internet.'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOS Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _gettingLocation ? null : _getLocation,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _gettingLocation
                          ? 'Getting location...'
                          : 'Get GPS location',
                    ),
                  ),
                  if (_locationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_locationMessage!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading || _isScanning ? null : _startScan,
                  icon: const Icon(Icons.search),
                  label: const Text('Start scan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? _stopScan : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop scan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isAdvertisingBusy || _isAdvertising
                      ? null
                      : _startAdvertising,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Start Advertising'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAdvertising ? _stopAdvertising : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop Advertising'),
                ),
              ),
            ],
          ),

          if (_advertiseMessage != null) ...[
            const SizedBox(height: 8),
            Text(_advertiseMessage!),
          ],
          if (_isLoading || _isScanning) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Searching for HERP devices...'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Discovered devices (${_devices.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_transferStatus != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_transferStatus!),
              ),
            ),

          if (_receivedMessage != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Received BLE message'),
                subtitle: Text(_receivedMessage!),
              ),
            ),
          if (_devices.isEmpty && !_isScanning && !_isLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No HERP devices found yet. '
                  'Another device must advertise the HERP service UUID.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ..._devices.values.map((result) {
            final name = result.advertisementData.advName;
            final displayName = name.isNotEmpty ? name : 'Unknown BLE device';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.smartphone),
                title: Text(displayName),
                subtitle: Text('ID: ${result.device.remoteId.str}'),
                trailing: IconButton(
                  tooltip: 'Send test message',
                  onPressed: _sendingDeviceId == result.device.remoteId.str
                      ? null
                      : () => _sendTestMessage(result),
                  icon: const Icon(Icons.send),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
