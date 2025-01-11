import 'package:flutter/foundation.dart';

class BleCharacteristicReadRequest {
  BleCharacteristicReadRequest({required this.uuid, required this.respond});

  final String uuid;
  final ValueChanged<int> respond;
}

class BleCharacteristicWriteRequest {
  BleCharacteristicWriteRequest({required this.uuid, required this.value});

  final String uuid;
  final int value;
}
