import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import 'ble_constants.dart';

class BleAdvertiseService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// Incoming SOS data written by a connected phone.
  Stream<Uint8List> get receivedData => _peripheral.onDataReceived;

  Future<String> startAdvertising() async {
    final supported = await _peripheral.isSupported;

    if (!supported) {
      return 'BLE advertising is not supported on this device.';
    }

    var permissionState = await _peripheral.hasPermission();

    if (permissionState != PeripheralBluetoothState.granted &&
        permissionState != PeripheralBluetoothState.ready) {
      permissionState = await _peripheral.requestPermission();
    }

    if (permissionState != PeripheralBluetoothState.granted &&
        permissionState != PeripheralBluetoothState.ready) {
      return 'Bluetooth permission or adapter is not ready: '
          '$permissionState';
    }

    final state = await _peripheral.start(
      advertiseData: Platform.isAndroid
          ? AndroidAdvertiseData(
              serviceUuid: BleConstants.herpServiceUuid,
            )
          : AdvertiseDataCore(
              serviceUuid: BleConstants.herpServiceUuid,
              localName: 'HERP',
            ),
      androidSettings: Platform.isAndroid
          ? const AndroidAdvertiseSettings(
              advertiseResponseData: AndroidAdvertiseData(
                includeDeviceName: true,
              ),
            )
          : null,
      gattServer: const GattServerSettings(),
    );

    return 'Advertising result: $state';
  }

  /// Send data to a connected central device.
  Future<void> sendData(Uint8List data) async {
    await _peripheral.sendData(data);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  Future<bool> get isAdvertising async => await _peripheral.isAdvertising;
}
