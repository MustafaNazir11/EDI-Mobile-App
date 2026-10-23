import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_constants.dart';

class BleScanService {
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults;

  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final permissions = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return permissions.values.every((permission) => permission.isGranted);
  }

  Future<void> startScan() async {
    final hasPermission = await requestPermissions();

    if (!hasPermission) {
      throw Exception(
        'Bluetooth permissions were denied. '
        'Please grant them in Android Settings.',
      );
    }

    final state = await FlutterBluePlus.adapterState.firstWhere(
      (state) => state != BluetoothAdapterState.unknown,
    );

    if (state != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is turned off. Please enable Bluetooth.');
    }

    await FlutterBluePlus.startScan(
      withServices: [Guid(BleConstants.herpServiceUuid)]
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
}
