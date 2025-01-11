import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_connection_state.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/ble_peripheral_manager.dart';

enum PeripheralListState { ready, disconnected }

class PeripheralListCubit extends Cubit<PeripheralListState> {
  PeripheralListCubit(this._manager) : super(PeripheralListState.ready);

  final BlePeripheralManager _manager;

  StreamSubscription? sub;

  Future<void> init() async {
    if (Platform.isAndroid) {
      sub = _manager.connectionStateStream.listen(_onConnectionStateChange);
    }
  }

  void disconnect() {
    emit(PeripheralListState.disconnected);
  }

  void _onConnectionStateChange(BleConnectionState state) {
    if (state == BleConnectionState.disconnected) {
      emit(PeripheralListState.disconnected);
    }
  }

  @override
  Future<void> close() {
    sub?.cancel();
    sub = null;

    return super.close();
  }
}
