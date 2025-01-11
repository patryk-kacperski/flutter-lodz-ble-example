import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_central_manager.dart';
import 'package:flutter_lodz_ble/model/peripheral.dart';
import 'package:flutter_lodz_ble/util/utils.dart';

/// An implementation of BleCentralManager using flutter_blue_plus package
/// https://pub.dev/packages/flutter_blue_plus
class FlutterBluePlusCentralManager implements BleCentralManager {
  final List<BluetoothDevice> _detectedDevices = [];

  BluetoothDevice? _connectedDevice;
  final List<BluetoothService> _connectedDeviceServices = [];

  @override
  Stream<DetectedPeripheralModel> get detectedDevicesStream =>
      FlutterBluePlus.onScanResults
          .where((results) => results.isNotEmpty)
          .map((results) {
        final newResult = results.last;
        _detectedDevices.add(newResult.device);
        return _mapScanResult(newResult);
      });

  @override
  Future<void> startScanning({List<String> names = const []}) async {
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    FlutterBluePlus.startScan(withNames: names);
  }

  @override
  void stopScanning() {
    FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connectToDevice({required String uuid}) async {
    final device = _detectedDevices
        .firstWhere((detectedDevice) => detectedDevice.remoteId.str == uuid);

    await device.connect();

    await device.connectionState
        .where((state) => state == BluetoothConnectionState.connected)
        .first;

    _connectedDevice = device;
  }

  @override
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;

    _connectedDeviceServices.clear();

    _detectedDevices.clear();

    stopScanning();
  }

  @override
  Future<int> read({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final characteristic = await _findCharacteristic(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );

    final value = await characteristic.read();
    return intFromUint8List(Uint8List.fromList(value));
  }

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required int value,
  }) async {
    final characteristic = await _findCharacteristic(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );

    final bytes = uInt8ListFromInt(value).toList();
    await characteristic.write(bytes, withoutResponse: true);
  }

  @override
  Stream<int> stream({
    required String serviceUuid,
    required String characteristicUuid,
  }) async* {
    final characteristic = await _findCharacteristic(
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );

    final stream = characteristic.onValueReceived.map((val) {
      return intFromUint8List(Uint8List.fromList(val));
    });

    await characteristic.setNotifyValue(true);

    yield* stream;
  }

  Future<BluetoothCharacteristic> _findCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final device = _connectedDevice;
    if (device == null) {
      throw StateError('No device connected, cannot read');
    }

    final services = _connectedDeviceServices.isNotEmpty
        ? _connectedDeviceServices
        : await device.discoverServices();

    final service = services.firstWhereOrNull((s) => s.uuid.str == serviceUuid);
    if (service == null) {
      throw StateError(
        'No service with id $serviceUuid defined on connected device',
      );
    }

    final characteristics = service.characteristics;
    final characteristic = characteristics.firstWhereOrNull(
      (ch) => ch.uuid.str == characteristicUuid,
    );
    if (characteristic == null) {
      throw StateError(
        'No characteristic with id $characteristicUuid defined on '
        'service $serviceUuid of the connected device',
      );
    }
    return characteristic;
  }

  DetectedPeripheralModel _mapScanResult(ScanResult result) {
    return DetectedPeripheralModel(
      name: result.advertisementData.advName,
      uuid: result.device.remoteId.str,
    );
  }
}
