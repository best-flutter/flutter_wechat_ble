import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter/material.dart';

class BleLogger extends ChangeNotifier {
  List<String> logger = [];

  int get length => logger.length;

  void add(String value) {
    logger.add(value);
    notifyListeners();
  }

  void clear() {
    logger.clear();
    notifyListeners();
  }
}

class BleModel {
  static BleModel instance = new BleModel();

  static BleLogger logger = new BleLogger();

  static String history;

  /// is bluetooth adapter opened?
  bool opening = false;

  /// is scanning devices ?
  bool scanning = false;

  static BleModel getInstance() {
    return instance;
  }

  Future shutdown() async {
    if (scanning) {
      try {
        await FlutterWechatBle.stopBluetoothDevicesDiscovery();
      } catch (e) {} finally {
        scanning = false;
      }
    }

    if (opening) {
      try {
        await FlutterWechatBle.closeBluetoothAdapter();
      } catch (e) {} finally {
        opening = false;
      }
    }
  }

  Future startup(FoundDeviceCallback success) async {
    try {
      await FlutterWechatBle.openBluetoothAdapter();
      opening = true;
    } catch (e) {
      await this.shutdown();
      return false;
    }
    try {
      FlutterWechatBle.onBluetoothDeviceFound(success);
      await FlutterWechatBle.startBluetoothDevicesDiscovery();
      scanning = true;
    } catch (e) {
      await this.shutdown();
      return false;
    }
    return true;
  }

  Future connect(BleDevice device) async {
    return FlutterWechatBle.createBLEConnection(deviceId: device.deviceId);
  }

  Future close(BleDevice device) async {
    return FlutterWechatBle.closeBLEConnection(deviceId: device.deviceId);
  }

  Future<List<BleService>> getServices(BleDevice device) async {
    return FlutterWechatBle.getBLEDeviceServices(device: device);
  }

  Future stopScan() async {
    return FlutterWechatBle.stopBluetoothDevicesDiscovery();
  }

  Future<List<BleCharacteristic>> getCharacteristics(
      BleDevice device, BleService service) {
    return FlutterWechatBle.getBLEDeviceCharacteristics(
        device: device, service: service);
  }

  Future changeNotifyState(BleDevice device, BleService service,
      BleCharacteristic characteristic, bool notify) async {
    return FlutterWechatBle.notifyBLECharacteristicValueChange(
        deviceId: device.deviceId,
        serviceId: service.uuid,
        characteristicId: characteristic.uuid,
        state: notify);
  }

  Future writeValue(BleDevice device, BleService service,
      BleCharacteristic characteristic, String value) async {
    if (!characteristic.write) {
      throw new Exception("Current characteristic does not supports write");
    }

    return FlutterWechatBle.writeBLECharacteristicValue(
        deviceId: device.deviceId,
        serviceId: service.uuid,
        characteristicId: characteristic.uuid,
        value: value);
  }

  void listenValueChanged(ValueChangeCallback callback) {
    FlutterWechatBle.onBLECharacteristicValueChange(callback);
  }
}
