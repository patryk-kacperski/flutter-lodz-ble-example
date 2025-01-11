class BleService {
  BleService({required this.uuid, required this.characteristics});

  final String uuid;
  final List<BleCharacteristic> characteristics;
}

class BleCharacteristic {
  BleCharacteristic({required this.uuid, required this.allowedOperations});

  final String uuid;
  final List<BleCharacteristicOperation> allowedOperations;
}

enum BleCharacteristicOperation { read, write, notify }
