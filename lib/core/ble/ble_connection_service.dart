import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import 'ble_constants.dart';

class BleConnectionService {
  Future<String> sendTestMessage(BluetoothDevice device) async {
    try {
      // Connect to the advertising phone.
      await device.connect(license: License.nonprofit);

      // Discover its GATT services.
      final services = await device.discoverServices();

      // Find the HERP service.
      final service = services.firstWhere(
        (service) => service.uuid == Guid(BleConstants.herpServiceUuid),
        orElse: () =>
            throw Exception('HERP service not found on the other phone.'),
      );

      // Find the RX characteristic used to receive data.
      final rxCharacteristic = service.characteristics.firstWhere(
        (characteristic) =>
            characteristic.uuid == Guid(defaultRxCharacteristicUuid),
        orElse: () => throw Exception('HERP receive characteristic not found.'),
      );

      // Send a small test message over BLE.
      final message = utf8.encode('HERP_TEST:Hello from the other phone!');

      await rxCharacteristic.write(message);

      return 'Test message sent successfully.';
    } catch (e) {
      return 'BLE transfer failed: $e';
    }
  }
}
