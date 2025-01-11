import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_connection_state.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_advertisement.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_peripheral_manager.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_service.dart';
import 'package:flutter_lodz_ble/model/peripheral.dart';
import 'package:flutter_lodz_ble/util/utils.dart';

sealed class PeripheralState {
  const PeripheralState();
}

final class PeripheralInitializingState extends PeripheralState {
  const PeripheralInitializingState();
}

final class PeripheralErrorState extends PeripheralState {
  const PeripheralErrorState();
}

sealed class PeripheralDataState extends PeripheralState {
  const PeripheralDataState({required this.model});

  final PeripheralModel model;
}

final class PeripheralInitializedState extends PeripheralDataState {
  const PeripheralInitializedState({required super.model});
}

final class PeripheralConnectedState extends PeripheralState {
  const PeripheralConnectedState();
}

class PeripheralCubit extends Cubit<PeripheralState> {
  PeripheralCubit(this._manager) : super(const PeripheralInitializingState());

  final BlePeripheralManager _manager;

  StreamSubscription? sub;

  Future<void> init() async {
    if (Platform.isAndroid) {
      sub = _manager.connectionStateStream.listen(_onConnectionStateChange);
    }

    await _addServices();

    final advertisement = BleAdvertisement(
      name: advertisedName,
      serviceUuids: [counterServiceUuid],
    );

    await _manager.startAdvertising(advertisement);

    const model = PeripheralModel(name: advertisedName);
    emit(const PeripheralInitializedState(model: model));
  }

  void _onConnectionStateChange(BleConnectionState state) {
    if (state == BleConnectionState.connected) {
      emit(const PeripheralConnectedState());
    }
  }

  Future<void> _addServices() async {
    final services = [
      BleService(
        uuid: counterServiceUuid,
        characteristics: [
          BleCharacteristic(
            uuid: counterReadCharacteristicUuid,
            allowedOperations: [BleCharacteristicOperation.read],
          ),
          BleCharacteristic(
            uuid: counterWriteCharacteristicUuid,
            allowedOperations: [BleCharacteristicOperation.write],
          ),
          BleCharacteristic(
            uuid: counterNotifyCharacteristicUuid,
            allowedOperations: [BleCharacteristicOperation.notify],
          ),
        ],
      ),
    ];

    for (final service in services) {
      await _manager.addService(service);
    }
  }

  @override
  Future<void> close() {
    sub?.cancel();
    sub = null;

    _manager.stopAdvertising();

    return super.close();
  }
}
