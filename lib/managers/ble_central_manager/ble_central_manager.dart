import 'dart:async';

import 'package:flutter_lodz_ble/model/peripheral.dart';

abstract interface class BleCentralManager {
  Stream<DetectedPeripheralModel> get detectedDevicesStream;

  Future<void> startScanning({List<String> names = const []});

  void stopScanning();

  Future<void> connectToDevice({required String uuid});

  Future<void> disconnect();

  Future<int> read({
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required int value,
  });

  Stream<int> stream({
    required String serviceUuid,
    required String characteristicUuid,
  });
}
