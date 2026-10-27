import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/location/location_service.dart';
import '../../sos/models/sos_message.dart';
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
  final Set<String> _handledSosIds = {};
  final String _relayDeviceId =
    'HERP-RELAY-${DateTime.now().microsecondsSinceEpoch}';

final Set<String> _relayingSosIds = {};

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
  _handleIncomingSos(data);
});

    _startRelayMode();
  }

  Future<void> _handleIncomingSos(Uint8List data) async {
  try {
    final rawMessage = utf8.decode(data);
    final sos = SosMessage.decode(rawMessage);

    // Handle each SOS only once during this app session.
    if (!_handledSosIds.add(sos.id)) return;

    if (!mounted) return;

    setState(() {
      _receivedMessage =
          'SOS received!\n'
          'ID: ${sos.id}\n'
          'Origin: ${sos.originDeviceId}\n'
          'Hops: ${sos.hopCount}\n'
          'Latitude: ${sos.latitude ?? "Unavailable"}\n'
          'Longitude: ${sos.longitude ?? "Unavailable"}';
    });

    debugPrint('HERP received SOS: ${sos.id}');

    // Forward without waiting for the UI or requiring a button tap.
    await _forwardSos(sos);
  } catch (e) {
    debugPrint('HERP received invalid SOS data: $e');
  }
}

Future<void> _forwardSos(SosMessage sos) async {
  if (!_relayingSosIds.add(sos.id)) return;

  try {
    // Prevent this relay from appearing twice in the route.
    if (sos.hasVisited(_relayDeviceId)) return;

    if (!sos.canForward) {
      debugPrint('HERP: maximum SOS hops reached: ${sos.id}');
      return;
    }

    final forwardedSos = sos.forwardedBy(_relayDeviceId);

    // Copy the list because scan results may change while sending.
    final nearbyDevices = List<ScanResult>.from(_devices.values);

    for (final result in nearbyDevices) {
      if (!mounted) break;

      final deviceId = result.device.remoteId.str;

      // Don't send back to a device whose ID is already in the route.
      if (forwardedSos.hasVisited(deviceId)) continue;

      final status = await _connectionService.sendSosMessage(
        result.device,
        forwardedSos,
      );

      debugPrint(
        'HERP relay ${sos.id} -> $deviceId: $status',
      );
    }
  } catch (e) {
    debugPrint('HERP forwarding failed for ${sos.id}: $e');
  } finally {
    _relayingSosIds.remove(sos.id);
  }
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

  Future<void> _startRelayMode() async {
  await _startAdvertising();

  if (!mounted) return;

  await _startScan();
}

Future<void> _sendTestMessage(ScanResult result) async {
  final deviceId = result.device.remoteId.str;
  final deviceName = _deviceDisplayName(result);

  setState(() {
    _sendingDeviceId = deviceId;
    _transferStatus = null;
  });

  try {
    final location = await _locationService.getCurrentLocation();

    final sos = SosMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}-$deviceId',
      originDeviceId: 'HERP-$deviceId',
      createdAt: DateTime.now().toUtc(),
      latitude: location.latitude,
      longitude: location.longitude,
    );

    _handledSosIds.add(sos.id);


    final message = await _connectionService.sendSosMessage(
      result.device,
      sos,
    );

    if (!mounted) return;

    setState(() {
      _transferStatus = '$deviceName: $message';
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _transferStatus = 'SOS transfer failed: $error';
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
            final displayName = _deviceDisplayName(result);

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

  String _deviceDisplayName(ScanResult result) {
    final advertisedName = result.advertisementData.advName.trim();
    if (advertisedName.isNotEmpty) return advertisedName;

    final platformName = result.device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;

    return 'HERP phone (${result.device.remoteId.str})';
  }
}
