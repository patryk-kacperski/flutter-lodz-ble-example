import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/ble_central_manager.dart';

enum CentralListState { ready, disconnecting, disconnected }

class CentralListCubit extends Cubit<CentralListState> {
  CentralListCubit(this._manager) : super(CentralListState.ready);

  final BleCentralManager _manager;

  Future<void> disconnect() async {
    emit(CentralListState.disconnecting);
    await _manager.disconnect();
    emit(CentralListState.disconnected);
  }
}