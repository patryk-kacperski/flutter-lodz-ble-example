import 'dart:io';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_lodz_ble/features/home/home_page.dart';
import 'package:flutter_lodz_ble/managers/ble_central_manager/flutter_blue_plus_central_manager.dart';
import 'package:flutter_lodz_ble/managers/ble_peripheral_manager/bluetooth_low_energy_peripheral_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class FlutterLodzBleApp extends StatelessWidget {
  const FlutterLodzBleApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterBluePlus.setLogLevel(LogLevel.verbose);

    return GlobalProviders(
      child: MaterialApp(
        title: 'Flutter Łódź BLE',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class GlobalProviders extends StatefulWidget {
  const GlobalProviders({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalProviders> createState() => _GlobalProvidersState();
}

class _GlobalProvidersState extends State<GlobalProviders> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothLowEnergyInternalPeripheralManager = PeripheralManager();

    return MultiProvider(
      providers: [
        Provider<BluetoothLowEnergyPeripheralManager>(
          create: (context) => BluetoothLowEnergyPeripheralManager(
            bluetoothLowEnergyInternalPeripheralManager,
          ),
        ),
        Provider<FlutterBluePlusCentralManager>(
          create: (context) => FlutterBluePlusCentralManager()
        ),
      ],
      child: widget.child,
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      await Permission.locationWhenInUse.request();
      await Permission.bluetooth.request();
    }
  }
}
