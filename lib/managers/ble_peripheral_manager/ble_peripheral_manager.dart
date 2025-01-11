import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_connection_state.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_advertisement.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_characteristic_requests.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_service.dart';

abstract interface class BlePeripheralManager {
  Stream<BleConnectionState> get connectionStateStream;

  Stream<BleCharacteristicReadRequest> get characteristicReadRequestsStream;

  Stream<BleCharacteristicWriteRequest> get characteristicWriteRequestsStream;

  Future<void> startAdvertising(BleAdvertisement advertisement);

  Future<void> stopAdvertising();

  Future<void> addService(BleService service);

  Future<void> notifyListener({
    required String serviceUuid,
    required String characteristicUuid,
    required int value,
  });
}
