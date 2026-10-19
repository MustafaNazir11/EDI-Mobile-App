import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import 'ble_constants.dart';

class BleAdvertiseService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

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
      advertiseData: AdvertiseDataCore(
        serviceUuid: BleConstants.herpServiceUuid,
      ),
    );

    return 'Advertising result: $state';
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  Future<bool> get isAdvertising async => await _peripheral.isAdvertising;
}
