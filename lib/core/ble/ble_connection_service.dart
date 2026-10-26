
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import 'ble_constants.dart';
import '../../features/sos/models/sos_message.dart';

class BleConnectionService {
  
Future<String> sendSosMessage(
  BluetoothDevice device,
  SosMessage sos,
) async {
  var stage = 'connecting';

  try {
    await device
        .connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 20),
        )
        .timeout(const Duration(seconds: 25));

    stage = 'discovering HERP service';

    final services = await device
        .discoverServices()
        .timeout(const Duration(seconds: 15));

    final service = services.firstWhere(
      (s) => s.uuid == Guid(BleConstants.herpServiceUuid),
      orElse: () => throw Exception(
        'HERP service not found on the receiving phone.',
      ),
    );

    stage = 'finding receive characteristic';

    final rxCharacteristic = service.characteristics.firstWhere(
      (c) => c.uuid == Guid(defaultRxCharacteristicUuid),
      orElse: () => throw Exception(
        'HERP receive characteristic not found.',
      ),
    );

    stage = 'writing SOS';

    final bytes = Uint8List.fromList(
      utf8.encode(sos.encode()),
    );

    await rxCharacteristic
        .write(bytes)
        .timeout(const Duration(seconds: 15));

    return 'SOS write completed. Remote receipt is not confirmed.';
  } catch (e) {
    return 'SOS failed while $stage: $e';
  }
}
}
