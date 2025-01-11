import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:collection/collection.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_connection_state.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_advertisement.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_characteristic_requests.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_peripheral_manager.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_service.dart';
import 'package:flutter_lodz_ble/util/utils.dart';

/// An implementation of BlePeripheralManager using bluetooth_low_energy package
/// https://pub.dev/packages/bluetooth_low_energy
class BluetoothLowEnergyPeripheralManager implements BlePeripheralManager {
  BluetoothLowEnergyPeripheralManager(this._manager);

  final PeripheralManager _manager;

  Central? _connectedCentral;

  final List<GATTService> _addedServices = [];

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _manager.connectionStateChanged.map((args) {
        switch (args.state) {
          case ConnectionState.disconnected:
            if (_connectedCentral?.uuid == args.central.uuid) {
              _connectedCentral = null;
              _addedServices.clear();
            }
            return BleConnectionState.disconnected;
          case ConnectionState.connected:
            _connectedCentral = args.central;
            return BleConnectionState.connected;
        }
      });

  @override
  Stream<BleCharacteristicReadRequest> get characteristicReadRequestsStream =>
      _manager.characteristicReadRequested.map((args) {
        return BleCharacteristicReadRequest(
          uuid: args.characteristic.uuid.toString(),
          respond: (value) {
            var bytes = uInt8ListFromInt(value);
            _manager.respondReadRequestWithValue(args.request, value: bytes);
          },
        );
      });

  @override
  Stream<BleCharacteristicWriteRequest> get characteristicWriteRequestsStream =>
      _manager.characteristicWriteRequested.map((args) {
        return BleCharacteristicWriteRequest(
          uuid: args.characteristic.uuid.toString(),
          value: intFromUint8List(args.request.value),
        );
      });

  @override
  Future<void> startAdvertising(BleAdvertisement advertisement) async {
    final bleAdvertisement = Advertisement(
      name: advertisement.name,
      serviceUUIDs: advertisement.serviceUuids.map(UUID.fromString).toList(),
    );
    return _manager.startAdvertising(bleAdvertisement);
  }

  @override
  Future<void> stopAdvertising() async {
    _manager.stopAdvertising();
  }

  @override
  Future<void> addService(BleService service) async {
    final gattService = _mapToGattService(service);
    await _manager.addService(gattService);
    _addedServices.add(gattService);
  }

  @override
  Future<void> notifyListener({
    required String serviceUuid,
    required String characteristicUuid,
    required int value,
  }) async {
    final central = _connectedCentral;
    if (central == null) {
      throw StateError('No central connected');
    }

    final service = _addedServices
        .firstWhereOrNull((s) => s.uuid.toString() == serviceUuid);
    if (service == null) {
      throw StateError('No service with id $serviceUuid added to this device');
    }

    final characteristic = service.characteristics
        .firstWhereOrNull((ch) => ch.uuid.toString() == characteristicUuid);
    if (characteristic == null) {
      throw StateError(
        'No characteristic with id $characteristicUuid is registered on '
        'service $serviceUuid',
      );
    }

    await _manager.notifyCharacteristic(
      central,
      characteristic,
      value: uInt8ListFromInt(value),
    );
  }

  List<GATTCharacteristicProperty> _mapToGattProperties(
    List<BleCharacteristicOperation> allowedOperations,
  ) {
    return allowedOperations
        .map((op) => switch (op) {
              BleCharacteristicOperation.read =>
                GATTCharacteristicProperty.read,
              BleCharacteristicOperation.write =>
                GATTCharacteristicProperty.writeWithoutResponse,
              BleCharacteristicOperation.notify =>
                GATTCharacteristicProperty.notify,
            })
        .toList();
  }

  List<GATTCharacteristicPermission> _mapToGattPermissions(
    List<BleCharacteristicOperation> allowedOperations,
  ) {
    return allowedOperations
        .map((op) => switch (op) {
              BleCharacteristicOperation.read =>
                GATTCharacteristicPermission.read,
              BleCharacteristicOperation.write =>
                GATTCharacteristicPermission.write,
              BleCharacteristicOperation.notify =>
                GATTCharacteristicPermission.read,
            })
        .toList();
  }

  GATTCharacteristic _mapToGattCharacteristic(
    BleCharacteristic characteristic,
  ) {
    return GATTCharacteristic.mutable(
      uuid: UUID.fromString(characteristic.uuid),
      properties: _mapToGattProperties(characteristic.allowedOperations),
      permissions: _mapToGattPermissions(characteristic.allowedOperations),
      descriptors: [],
    );
  }

  GATTService _mapToGattService(BleService service) {
    return GATTService(
      uuid: UUID.fromString(service.uuid),
      isPrimary: true,
      includedServices: [],
      characteristics:
          service.characteristics.map(_mapToGattCharacteristic).toList(),
    );
  }
}
