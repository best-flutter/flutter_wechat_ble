import 'package:easy_alert/easy_alert.dart';
import 'package:flutter_wechat_ble/flutter_wechat_ble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat_ble/bluetooth_service.dart';
import 'package:flutter_wechat_ble_example/services/TbkDeviceConfig.dart';

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

  void onConnectionStateChange(ConnectionStateChangeCallback callback) {
    FlutterWechatBle.onBLEConnectionStateChange(
        (String deviceId, bool connected) {
      callback(deviceId, connected);
    });
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
    } on BleError catch (e) {
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
    // 从缓存取出来,这里因为原生层面已经做了一次缓存，所以也可以直接调用
    if (device.services == null) {
      device.services = await FlutterWechatBle.getBLEDeviceServices(
          deviceId: device.deviceId);
    }
    return device.services;
  }

  Future stopScan() async {
    return FlutterWechatBle.stopBluetoothDevicesDiscovery();
  }

  Future<List<BleCharacteristic>> getCharacteristics(
      BleDevice device, BleService service) async {
    if (service.characteristics == null) {
      service.characteristics =
          await FlutterWechatBle.getBLEDeviceCharacteristics(
              deviceId: device.deviceId, serviceId: service.uuid);
    }

    return service.characteristics;
  }

  Future<BleValue> readValue(
      BleDevice device, BleService service, BleCharacteristic characteristic) {
    return FlutterWechatBle.readBLECharacteristicValue(
        deviceId: device.deviceId,
        serviceId: service.uuid,
        characteristicId: characteristic.uuid);
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
    return FlutterWechatBle.writeBLECharacteristicValue(
        deviceId: device.deviceId,
        serviceId: service.uuid,
        characteristicId: characteristic.uuid,
        value: value);
  }

  void listenConnectionStateChange(ConnectionStateChangeCallback callback) {
    FlutterWechatBle.onBLEConnectionStateChange(callback);
  }

  void listenValueChanged(ValueChangeCallback callback) {
    FlutterWechatBle.onBLECharacteristicValueChange(callback);
  }
}
