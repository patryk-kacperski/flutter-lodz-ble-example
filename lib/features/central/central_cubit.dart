import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_central_manager.dart';
import 'package:flutter_lodz_ble/model/peripheral.dart';
import 'package:flutter_lodz_ble/util/utils.dart';

sealed class CentralState {
  const CentralState();

  List<DetectedPeripheralModel> get peripherals => [];
}

sealed class CentralLoadingState extends CentralState {
  const CentralLoadingState();

  String get loadingText;
}

final class CentralInitializingState extends CentralLoadingState {
  const CentralInitializingState();

  @override
  String get loadingText => 'Initializing BLE Central...';
}

final class CentralSearchingState extends CentralLoadingState {
  const CentralSearchingState();

  @override
  String get loadingText => 'Searching for peripherals...';
}

final class CentralDataState extends CentralState {
  const CentralDataState({required this.peripherals});

  @override
  final List<DetectedPeripheralModel> peripherals;
}

final class CentralConnectingState extends CentralLoadingState {
  const CentralConnectingState({required this.peripheral});

  final DetectedPeripheralModel peripheral;

  @override
  String get loadingText => 'Connecting to ${peripheral.name}...';
}

final class CentralConnectedState extends CentralState {
  const CentralConnectedState({required this.peripheral});

  final DetectedPeripheralModel peripheral;
}

final class CentralErrorState extends CentralState {
  const CentralErrorState();
}

class CentralCubit extends Cubit<CentralState> {
  CentralCubit(this._manager) : super(const CentralInitializingState());

  final BleCentralManager _manager;

  StreamSubscription? _sub;

  List<DetectedPeripheralModel> get _peripherals => state.peripherals;

  Future<void> init() async {
    emit(const CentralSearchingState());

    _sub = _manager.detectedDevicesStream.listen(_onDetectedDevice);

    _manager.startScanning(names: [advertisedName]);
  }

  Future<void> connectToPeripheral({required String uuid}) async {
    final peripheral = _peripherals.firstWhereOrNull((p) => p.uuid == uuid);

    if (peripheral == null) {
      emit(const CentralErrorState());
      return;
    }

    emit(CentralConnectingState(peripheral: peripheral));

    await _manager.connectToDevice(uuid: uuid);
    emit(CentralConnectedState(peripheral: peripheral));
  }

  void _onDetectedDevice(DetectedPeripheralModel peripheral) {
    final peripherals = [..._peripherals, peripheral];
    emit(CentralDataState(peripherals: peripherals));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _sub = null;

    _manager.stopScanning();

    return super.close();
  }
}
